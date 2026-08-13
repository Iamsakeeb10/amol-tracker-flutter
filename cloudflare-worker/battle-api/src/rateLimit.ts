import type { Env } from './types.js';
import { rateLimitedError } from './errors.js';

/**
 * Validates a soft rate limit using KV.
 * Keeps an array of timestamps. If length >= maxRequests, throws rateLimitedError.
 * 
 * @param env The environment containing BATTLE_CODES KV
 * @param key The unique key for this rate limit (e.g. `rl:create:uid`)
 * @param maxRequests Maximum requests allowed in the window
 * @param windowMs The time window in milliseconds
 */
export async function checkRateLimit(
  env: Env,
  key: string,
  maxRequests: number,
  windowMs: number
): Promise<void> {
  const now = Date.now();
  let timestamps: number[] = [];
  
  try {
    const raw = await env.BATTLE_CODES.get(key, 'json');
    if (Array.isArray(raw)) {
      timestamps = raw as number[];
    }
  } catch {
    // Ignore parse errors, just start fresh
  }

  // Filter out expired timestamps
  timestamps = timestamps.filter(ts => now - ts < windowMs);

  if (timestamps.length >= maxRequests) {
    throw rateLimitedError('Too many requests, please try again later');
  }

  timestamps.push(now);

  // Save back to KV with expiration TTL set to the window size in seconds
  // Math.ceil is used to ensure TTL is at least 60 (minimum allowed by KV is 60s)
  const expirationTtl = Math.max(60, Math.ceil(windowMs / 1000));
  await env.BATTLE_CODES.put(key, JSON.stringify(timestamps), { expirationTtl });
}
