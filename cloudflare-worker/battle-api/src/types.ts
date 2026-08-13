// ---------------------------------------------------------------------------
// Shared TypeScript types for the battle-api Worker.
// ---------------------------------------------------------------------------

/**
 * Worker environment bindings.
 *
 * Vars and secrets injected via wrangler.toml / `wrangler secret put`.
 * Extend this interface as new bindings (KV, etc.) are added in later chunks.
 */
export interface Env {
  /** Firebase project ID — used to validate JWT audience/issuer claims. */
  FIREBASE_PROJECT_ID: string;

  // --- Future bindings (added in later chunks) ---
  BATTLE_CODES: KVNamespace;   // A3 — battle code registry
  // RATE_LIMIT: KVNamespace;     // A8 — rate limiting counters
  GOOGLE_SERVICE_ACCOUNT_JSON: string; // A2 — Firestore REST client
}

/**
 * Successful auth result — the verified Firebase user's UID.
 */
export interface AuthResult {
  uid: string;
}

/**
 * All error codes used across the battle-api, per the SDD.
 * Added incrementally as endpoints are built.
 */
export type BattleErrorCode =
  | 'unauthorized'
  | 'invalid_config'
  | 'rate_limited'
  | 'not_found'
  | 'already_started'
  | 'full'
  | 'already_joined'
  | 'not_host'
  | 'not_enough_players'
  | 'already_answered'
  | 'question_expired'
  | 'not_in_battle'
  | 'internal_error';
