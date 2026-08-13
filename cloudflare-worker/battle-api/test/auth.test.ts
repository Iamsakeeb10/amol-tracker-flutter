// ---------------------------------------------------------------------------
// Unit tests for the verifyAuth() module.
//
// These tests run inside the Cloudflare Workers runtime (via miniflare) so
// Web Crypto API, caches.default, and fetch() all work natively.
//
// We test with synthetically generated JWTs (signed with our own RSA key pair)
// and mock the JWKS endpoint to return matching public keys. This gives us
// full control over every scenario without needing a real Firebase project.
// ---------------------------------------------------------------------------

import { describe, it, expect, beforeAll, vi } from 'vitest';
import { verifyAuth } from '../src/auth.js';
import type { Env } from '../src/types.js';
import { ApiError } from '../src/errors.js';

// ---------------------------------------------------------------------------
// Test RSA key pair (generated once, used across all tests)
// ---------------------------------------------------------------------------

let rsaKeyPair: CryptoKeyPair;
let rsaPublicJwk: JsonWebKey;
const TEST_KID = 'test-key-id-001';
const TEST_PROJECT_ID = 'amol-tracker';

const testEnv = {
  FIREBASE_PROJECT_ID: TEST_PROJECT_ID,
  GOOGLE_SERVICE_ACCOUNT_JSON: '',
  BATTLE_CODES: {} as KVNamespace,
} as Env;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function base64UrlEncode(input: string | Uint8Array): string {
  const bytes =
    typeof input === 'string' ? new TextEncoder().encode(input) : input;
  let str = '';
  for (let i = 0; i < bytes.length; i++) {
    str += String.fromCharCode(bytes[i]!);
  }
  return btoa(str).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}

/**
 * Build a signed JWT with the given payload overrides.
 * Uses the test RSA key pair generated in beforeAll().
 */
async function buildTestJwt(
  payloadOverrides: Record<string, unknown> = {},
  headerOverrides: Record<string, unknown> = {},
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  const header = {
    alg: 'RS256',
    typ: 'JWT',
    kid: TEST_KID,
    ...headerOverrides,
  };

  const payload = {
    iss: `https://securetoken.google.com/${TEST_PROJECT_ID}`,
    aud: TEST_PROJECT_ID,
    sub: 'test-user-uid-123',
    iat: now - 60,
    exp: now + 3600,
    auth_time: now - 120,
    ...payloadOverrides,
  };

  const headerB64 = base64UrlEncode(JSON.stringify(header));
  const payloadB64 = base64UrlEncode(JSON.stringify(payload));
  const signingInput = `${headerB64}.${payloadB64}`;

  const signature = await crypto.subtle.sign(
    { name: 'RSASSA-PKCS1-v1_5' },
    rsaKeyPair.privateKey,
    new TextEncoder().encode(signingInput),
  );

  const signatureB64 = base64UrlEncode(new Uint8Array(signature));
  return `${signingInput}.${signatureB64}`;
}

function makeRequest(token?: string): Request {
  const headers = new Headers();
  if (token !== undefined) {
    headers.set('Authorization', `Bearer ${token}`);
  }
  return new Request('https://battle-api.test/auth/test', { headers });
}

function makeRequestNoAuth(): Request {
  return new Request('https://battle-api.test/auth/test');
}

function makeRequestBasicAuth(): Request {
  const headers = new Headers();
  headers.set('Authorization', 'Basic dXNlcjpwYXNz');
  return new Request('https://battle-api.test/auth/test', { headers });
}

// ---------------------------------------------------------------------------
// Setup: generate RSA keys and mock the JWKS endpoint
// ---------------------------------------------------------------------------

beforeAll(async () => {
  // Generate a fresh RSA key pair for testing
  rsaKeyPair = (await crypto.subtle.generateKey(
    {
      name: 'RSASSA-PKCS1-v1_5',
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: 'SHA-256',
    },
    true, // extractable — so we can export the public key as JWK
    ['sign', 'verify'],
  )) as CryptoKeyPair;

  // Export public key as JWK for the mock JWKS response
  rsaPublicJwk = (await crypto.subtle.exportKey('jwk', rsaKeyPair.publicKey)) as JsonWebKey;

  // Mock the global fetch to intercept JWKS requests
  const originalFetch = globalThis.fetch;
  vi.stubGlobal('fetch', async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = typeof input === 'string' ? input : input instanceof URL ? input.toString() : input.url;

    if (url.includes('googleapis.com/service_accounts/v1/jwk/securetoken')) {
      // Return our test JWKS
      return new Response(
        JSON.stringify({
          keys: [
            {
              kid: TEST_KID,
              kty: rsaPublicJwk.kty,
              alg: 'RS256',
              use: 'sig',
              n: rsaPublicJwk.n,
              e: rsaPublicJwk.e,
            },
          ],
        }),
        {
          status: 200,
          headers: { 'content-type': 'application/json' },
        },
      );
    }

    // Pass through any other fetch calls
    return originalFetch(input, init);
  });
});

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('verifyAuth', () => {
  it('returns uid for a valid token', async () => {
    const token = await buildTestJwt({ sub: 'user-abc-123' });
    const request = makeRequest(token);
    const result = await verifyAuth(request, testEnv);

    expect(result).toEqual({ uid: 'user-abc-123' });
  });

  it('rejects an expired token without crashing', async () => {
    const pastTime = Math.floor(Date.now() / 1000) - 7200; // 2 hours ago
    const token = await buildTestJwt({
      iat: pastTime - 3600,
      exp: pastTime, // expired 2 hours ago
    });
    const request = makeRequest(token);

    await expect(verifyAuth(request, testEnv)).rejects.toThrow(ApiError);

    try {
      await verifyAuth(request, testEnv);
    } catch (err) {
      expect(err).toBeInstanceOf(ApiError);
      const apiErr = err as ApiError;
      expect(apiErr.code).toBe('unauthorized');
      expect(apiErr.message).toContain('expired');
      expect(apiErr.httpStatus).toBe(401);
    }
  });

  it('rejects a missing Authorization header', async () => {
    const request = makeRequestNoAuth();

    await expect(verifyAuth(request, testEnv)).rejects.toThrow(ApiError);

    try {
      await verifyAuth(request, testEnv);
    } catch (err) {
      const apiErr = err as ApiError;
      expect(apiErr.code).toBe('unauthorized');
      expect(apiErr.message).toContain('Missing');
      expect(apiErr.httpStatus).toBe(401);
    }
  });

  it('rejects a malformed/garbage token', async () => {
    const request = makeRequest('this.is.notavalidtoken');

    await expect(verifyAuth(request, testEnv)).rejects.toThrow(ApiError);

    try {
      await verifyAuth(request, testEnv);
    } catch (err) {
      const apiErr = err as ApiError;
      expect(apiErr.code).toBe('unauthorized');
      expect(apiErr.httpStatus).toBe(401);
    }
  });

  it('rejects a non-Bearer Authorization header', async () => {
    const request = makeRequestBasicAuth();

    await expect(verifyAuth(request, testEnv)).rejects.toThrow(ApiError);

    try {
      await verifyAuth(request, testEnv);
    } catch (err) {
      const apiErr = err as ApiError;
      expect(apiErr.code).toBe('unauthorized');
      expect(apiErr.message).toContain('Malformed');
    }
  });

  it('rejects a token with wrong audience', async () => {
    const token = await buildTestJwt({ aud: 'wrong-project-id' });
    const request = makeRequest(token);

    await expect(verifyAuth(request, testEnv)).rejects.toThrow(ApiError);

    try {
      await verifyAuth(request, testEnv);
    } catch (err) {
      const apiErr = err as ApiError;
      expect(apiErr.code).toBe('unauthorized');
      expect(apiErr.message).toContain('audience');
    }
  });

  it('rejects a token with wrong issuer', async () => {
    const token = await buildTestJwt({
      iss: 'https://securetoken.google.com/wrong-project',
    });
    const request = makeRequest(token);

    await expect(verifyAuth(request, testEnv)).rejects.toThrow(ApiError);

    try {
      await verifyAuth(request, testEnv);
    } catch (err) {
      const apiErr = err as ApiError;
      expect(apiErr.code).toBe('unauthorized');
      expect(apiErr.message).toContain('issuer');
    }
  });

  it('rejects a token with missing subject', async () => {
    const token = await buildTestJwt({ sub: '' });
    const request = makeRequest(token);

    await expect(verifyAuth(request, testEnv)).rejects.toThrow(ApiError);

    try {
      await verifyAuth(request, testEnv);
    } catch (err) {
      const apiErr = err as ApiError;
      expect(apiErr.code).toBe('unauthorized');
      expect(apiErr.message).toContain('subject');
    }
  });

  it('rejects a token with unknown kid (key not in JWKS)', async () => {
    const token = await buildTestJwt({}, { kid: 'nonexistent-key-id' });
    const request = makeRequest(token);

    await expect(verifyAuth(request, testEnv)).rejects.toThrow(ApiError);

    try {
      await verifyAuth(request, testEnv);
    } catch (err) {
      const apiErr = err as ApiError;
      expect(apiErr.code).toBe('unauthorized');
      expect(apiErr.message).toContain('key not found');
    }
  });

  it('does not re-fetch JWKS on subsequent calls (cache hit)', async () => {
    // This test verifies caching behavior by counting fetch calls.
    // The JWKS fetch is mocked in beforeAll, and caches.default is provided
    // by miniflare. After the first call warms the cache, subsequent calls
    // should hit the cache and NOT trigger another fetch to the JWKS URL.

    let jwksFetchCount = 0;
    const originalFetch = globalThis.fetch;

    // Temporarily replace with a counting wrapper
    const countingFetch = async (input: RequestInfo | URL, init?: RequestInit) => {
      const url =
        typeof input === 'string'
          ? input
          : input instanceof URL
            ? input.toString()
            : input.url;

      if (url.includes('googleapis.com/service_accounts/v1/jwk/securetoken')) {
        jwksFetchCount++;
      }
      return originalFetch(input, init);
    };
    vi.stubGlobal('fetch', countingFetch);

    // Clear the cache to start fresh
    const cache = caches.default;
    const cacheKey = new Request(
      'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
    );
    await cache.delete(cacheKey);

    // First call — should fetch JWKS
    const token1 = await buildTestJwt({ sub: 'cache-test-user-1' });
    await verifyAuth(makeRequest(token1), testEnv);
    expect(jwksFetchCount).toBe(1);

    // Second call — should use cached JWKS
    const token2 = await buildTestJwt({ sub: 'cache-test-user-2' });
    await verifyAuth(makeRequest(token2), testEnv);
    expect(jwksFetchCount).toBe(1); // still 1, no re-fetch
  });
});
