// ---------------------------------------------------------------------------
// Google Service Account OAuth2 Authentication for Cloudflare Workers.
//
// Exchanges the GOOGLE_SERVICE_ACCOUNT_JSON secret for a short-lived
// Google OAuth2 access token to be used with the Firestore REST API.
// Implements an in-memory isolate cache to avoid re-authenticating on
// every request.
// ---------------------------------------------------------------------------

import type { Env } from '../types.js';
import { internalError } from '../errors.js';

let cachedAccessToken: string | null = null;
let tokenExp = 0; // seconds since epoch

export async function getGoogleAccessToken(env: Env): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  // Return cached token if valid (add a 5-minute buffer before expiration)
  if (cachedAccessToken && tokenExp > now + 300) {
    return cachedAccessToken;
  }

  if (!env.GOOGLE_SERVICE_ACCOUNT_JSON) {
    throw internalError('GOOGLE_SERVICE_ACCOUNT_JSON is missing');
  }

  let sa: { client_email?: string; private_key?: string };
  try {
    sa = JSON.parse(env.GOOGLE_SERVICE_ACCOUNT_JSON);
  } catch {
    throw internalError('GOOGLE_SERVICE_ACCOUNT_JSON is invalid JSON');
  }

  const clientEmail = sa.client_email;
  const privateKey = sa.private_key;
  if (!clientEmail || !privateKey) {
    throw internalError('Service account missing client_email or private_key');
  }

  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: clientEmail,
    sub: clientEmail,
    aud: 'https://oauth2.googleapis.com/token',
    // Scopes needed for Firestore REST API
    scope:
      'https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/cloud-platform',
    iat: now,
    exp: now + 3600, // JWT valid for 1 hour
  };

  const unsigned = `${base64UrlEncode(JSON.stringify(header))}.${base64UrlEncode(
    JSON.stringify(payload),
  )}`;

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(privateKey),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign(
    { name: 'RSASSA-PKCS1-v1_5' },
    key,
    new TextEncoder().encode(unsigned),
  );

  const jwt = `${unsigned}.${base64UrlEncode(new Uint8Array(signature))}`;

  // Exchange JWT for OAuth2 Access Token
  const tokenResp = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  if (!tokenResp.ok) {
    const errorBody = await tokenResp.text();
    throw internalError(`OAuth token exchange failed: ${tokenResp.status} ${errorBody}`);
  }

  const tokenJson = (await tokenResp.json()) as { access_token?: string; expires_in?: number };
  if (!tokenJson.access_token) {
    throw internalError('OAuth token response missing access_token');
  }

  // Cache the token
  cachedAccessToken = tokenJson.access_token;
  // Usually expires in 3600 seconds
  tokenExp = now + (tokenJson.expires_in ?? 3600);

  return cachedAccessToken;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function base64UrlEncode(input: string | Uint8Array): string {
  const bytes = typeof input === 'string' ? new TextEncoder().encode(input) : input;
  let str = '';
  for (let i = 0; i < bytes.length; i++) {
    str += String.fromCharCode(bytes[i]!);
  }
  return btoa(str).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const cleaned = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s+/g, '');
  const binary = atob(cleaned);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}
