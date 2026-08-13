// ---------------------------------------------------------------------------
// Firebase ID Token verification via JWKS for Cloudflare Workers.
//
// This module is the core deliverable of Chunk A1. It verifies Firebase
// ID tokens by:
//   1. Extracting the Bearer token from the Authorization header
//   2. Fetching (and caching) Firebase's public JWKS keys
//   3. Verifying the RS256 signature using Web Crypto API
//   4. Validating all standard JWT claims (exp, iat, aud, iss, sub)
//
// Unlike the existing workers' `verifyFirebaseIdToken()` which calls the
// Identity Toolkit REST API (a simple lookup, not cryptographic verification),
// this performs proper JWT verification locally — faster, more secure, and
// doesn't require FIREBASE_WEB_API_KEY.
// ---------------------------------------------------------------------------

import type { Env, AuthResult } from './types.js';
import { unauthorizedError } from './errors.js';

/** Firebase's public JWKS endpoint for `securetoken` service account. */
const FIREBASE_JWKS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

/** How long to cache the JWKS response (seconds). Google rotates keys ~every 6h. */
const JWKS_CACHE_TTL_SECONDS = 3600; // 1 hour

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Verify a Firebase ID token from the request's Authorization header.
 *
 * @returns The verified user's UID.
 * @throws {ApiError} with code `'unauthorized'` on any failure.
 */
export async function verifyAuth(request: Request, env: Env): Promise<AuthResult> {
  const token = extractBearerToken(request);
  const { header, payload, signatureInput, signatureBytes } = decodeJwt(token);

  // Validate header algorithm
  if (header.alg !== 'RS256') {
    throw unauthorizedError('Unsupported token algorithm');
  }
  if (!header.kid || typeof header.kid !== 'string') {
    throw unauthorizedError('Token missing key ID');
  }

  // Fetch the matching public key from Firebase's JWKS (cached)
  const publicKey = await getSigningKey(header.kid);

  // Verify the RS256 signature
  const isValid = await crypto.subtle.verify(
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    publicKey,
    signatureBytes,
    new TextEncoder().encode(signatureInput),
  );
  if (!isValid) {
    throw unauthorizedError('Token signature invalid');
  }

  // Validate standard claims
  validateClaims(payload, env);

  const uid = payload.sub;
  if (!uid || typeof uid !== 'string') {
    throw unauthorizedError('Token missing subject');
  }

  return { uid };
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/** Extract the Bearer token from the Authorization header. */
function extractBearerToken(request: Request): string {
  const authHeader = request.headers.get('Authorization');
  if (!authHeader) {
    throw unauthorizedError('Missing Authorization header');
  }

  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer' || !parts[1]) {
    throw unauthorizedError('Malformed Authorization header');
  }

  return parts[1];
}

// ---------------------------------------------------------------------------
// JWT decoding (no verification — just base64url decode)
// ---------------------------------------------------------------------------

interface JwtHeader {
  alg: string;
  kid?: string;
  typ?: string;
  [key: string]: unknown;
}

interface JwtPayload {
  iss?: string;
  sub?: string;
  aud?: string;
  exp?: number;
  iat?: number;
  auth_time?: number;
  [key: string]: unknown;
}

interface DecodedJwt {
  header: JwtHeader;
  payload: JwtPayload;
  /** The `header.payload` string that was signed (used for signature verification). */
  signatureInput: string;
  /** Raw signature bytes. */
  signatureBytes: Uint8Array;
}

/** Decode a JWT into its three parts without verifying. */
function decodeJwt(token: string): DecodedJwt {
  const parts = token.split('.');
  if (parts.length !== 3 || !parts[0] || !parts[1] || !parts[2]) {
    throw unauthorizedError('Malformed token structure');
  }

  let header: JwtHeader;
  let payload: JwtPayload;
  try {
    header = JSON.parse(base64UrlDecode(parts[0])) as JwtHeader;
  } catch {
    throw unauthorizedError('Malformed token header');
  }
  try {
    payload = JSON.parse(base64UrlDecode(parts[1])) as JwtPayload;
  } catch {
    throw unauthorizedError('Malformed token payload');
  }

  let signatureBytes: Uint8Array;
  try {
    signatureBytes = base64UrlDecodeBytes(parts[2]);
  } catch {
    throw unauthorizedError('Malformed token signature');
  }

  return {
    header,
    payload,
    signatureInput: `${parts[0]}.${parts[1]}`,
    signatureBytes,
  };
}

// ---------------------------------------------------------------------------
// JWKS fetching + caching
// ---------------------------------------------------------------------------

interface JwkKey {
  kid: string;
  kty: string;
  alg: string;
  use: string;
  n: string;
  e: string;
}

interface JwksResponse {
  keys: JwkKey[];
}

/**
 * Fetch the JWKS from Firebase and cache the response using the Workers
 * Cache API. On cache hit, returns immediately without a network call.
 */
async function fetchJwks(): Promise<JwksResponse> {
  const cache = caches.default;
  const cacheKey = new Request(FIREBASE_JWKS_URL);

  // Try cache first
  const cachedResponse = await cache.match(cacheKey);
  if (cachedResponse) {
    return cachedResponse.json() as Promise<JwksResponse>;
  }

  // Cache miss — fetch from Google
  const response = await fetch(FIREBASE_JWKS_URL);
  if (!response.ok) {
    throw unauthorizedError('Failed to fetch signing keys');
  }

  // Clone the response so we can read it AND store it in cache
  const responseToCache = new Response(response.body, {
    status: response.status,
    headers: {
      'content-type': 'application/json',
      'cache-control': `public, max-age=${JWKS_CACHE_TTL_SECONDS}`,
    },
  });
  // Put in cache (non-blocking — don't await, it's fire-and-forget)
  await cache.put(cacheKey, responseToCache.clone());

  return responseToCache.json() as Promise<JwksResponse>;
}

/**
 * Get the CryptoKey for a specific `kid` from the JWKS.
 * Imports the JWK as a Web Crypto key for RS256 verification.
 */
async function getSigningKey(kid: string): Promise<CryptoKey> {
  const jwks = await fetchJwks();
  const jwk = jwks.keys.find((k) => k.kid === kid);

  if (!jwk) {
    throw unauthorizedError('Token signing key not found');
  }

  return crypto.subtle.importKey(
    'jwk',
    {
      kty: jwk.kty,
      n: jwk.n,
      e: jwk.e,
      alg: 'RS256',
      ext: true,
    },
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['verify'],
  );
}

// ---------------------------------------------------------------------------
// Claim validation
// ---------------------------------------------------------------------------

/** Validate the standard Firebase ID token claims. */
function validateClaims(payload: JwtPayload, env: Env): void {
  const now = Math.floor(Date.now() / 1000);

  // Check expiration
  if (typeof payload.exp !== 'number' || payload.exp <= now) {
    throw unauthorizedError('Token expired');
  }

  // Check issued-at (must not be in the future)
  if (typeof payload.iat !== 'number' || payload.iat > now) {
    throw unauthorizedError('Token issued in the future');
  }

  // Check audience (must be our Firebase project)
  if (payload.aud !== env.FIREBASE_PROJECT_ID) {
    throw unauthorizedError('Token audience mismatch');
  }

  // Check issuer
  const expectedIssuer = `https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}`;
  if (payload.iss !== expectedIssuer) {
    throw unauthorizedError('Token issuer mismatch');
  }

  // Check subject (the Firebase UID) exists
  if (!payload.sub || typeof payload.sub !== 'string') {
    throw unauthorizedError('Token missing subject');
  }
}

// ---------------------------------------------------------------------------
// Base64URL utilities
// ---------------------------------------------------------------------------

/** Decode a base64url-encoded string to a UTF-8 string. */
function base64UrlDecode(input: string): string {
  const padded = input.replace(/-/g, '+').replace(/_/g, '/');
  const paddedFull = padded + '='.repeat((4 - (padded.length % 4)) % 4);
  const binary = atob(paddedFull);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return new TextDecoder().decode(bytes);
}

/** Decode a base64url-encoded string to raw bytes. */
function base64UrlDecodeBytes(input: string): Uint8Array {
  const padded = input.replace(/-/g, '+').replace(/_/g, '/');
  const paddedFull = padded + '='.repeat((4 - (padded.length % 4)) % 4);
  const binary = atob(paddedFull);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}
