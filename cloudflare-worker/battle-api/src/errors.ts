// ---------------------------------------------------------------------------
// Consistent error responses for the battle-api Worker.
//
// Every error returned by any endpoint uses the shape:
//   { error: string, code: BattleErrorCode }
//
// This is established here in Chunk A1 so it never drifts — per the Dev
// Guide §4 and §8.
// ---------------------------------------------------------------------------

import type { BattleErrorCode } from './types.js';

/**
 * A typed API error that can be thrown from any handler and caught at the
 * top-level to produce a consistent JSON response.
 */
export class ApiError extends Error {
  readonly code: BattleErrorCode;
  readonly httpStatus: number;

  constructor(code: BattleErrorCode, message: string, httpStatus: number) {
    super(message);
    this.name = 'ApiError';
    this.code = code;
    this.httpStatus = httpStatus;
  }

  /** Serialize to the standard `{ error, code }` JSON response. */
  toResponse(): Response {
    return jsonResponse({ error: this.message, code: this.code }, this.httpStatus);
  }
}

// ---------------------------------------------------------------------------
// Convenience constructors — one per error code used so far.
// More will be added in later chunks as endpoints are built.
// ---------------------------------------------------------------------------

/** 401 — missing, malformed, or expired Firebase ID token. */
export function unauthorizedError(detail = 'Unauthorized'): ApiError {
  return new ApiError('unauthorized', detail, 401);
}

/** 404 — generic not-found (never reveals whether a resource existed). */
export function notFoundError(detail = 'Not found'): ApiError {
  return new ApiError('not_found', detail, 404);
}

/** 400 — invalid configuration or arguments provided by client. */
export function invalidConfigError(detail = 'Invalid configuration'): ApiError {
  return new ApiError('invalid_config', detail, 400);
}

/** 409 — action cannot be performed because battle already started. */
export function alreadyStartedError(detail = 'Battle already started'): ApiError {
  return new ApiError('already_started', detail, 409);
}

/** 409 — action cannot be performed because battle is full. */
export function fullError(detail = 'Battle is full'): ApiError {
  return new ApiError('full', detail, 409);
}

/** 409 — player already joined the battle. */
export function alreadyJoinedError(detail = 'Already joined'): ApiError {
  return new ApiError('already_joined', detail, 409);
}

/** 403 — action cannot be performed because user is not the host. */
export function notHostError(detail = 'Not the host'): ApiError {
  return new ApiError('not_host', detail, 403);
}

/** 409 — action cannot be performed because there are not enough players. */
export function notEnoughPlayersError(detail = 'Not enough players'): ApiError {
  return new ApiError('not_enough_players', detail, 409);
}

/** 409 — user has already submitted an answer for this question. */
export function alreadyAnsweredError(detail = 'Already answered'): ApiError {
  return new ApiError('already_answered', detail, 409);
}

/** 429 — rate limit exceeded. */
export function rateLimitedError(detail = 'Too many requests'): ApiError {
  return new ApiError('rate_limited', detail, 429);
}

/** 500 — unexpected internal failure. */
export function internalError(detail = 'Internal server error'): ApiError {
  return new ApiError('internal_error', detail, 500);
}

// ---------------------------------------------------------------------------
// Response helpers
// ---------------------------------------------------------------------------

/** Return a JSON response with the given body and HTTP status. */
export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });
}
