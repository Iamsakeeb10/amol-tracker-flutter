// ---------------------------------------------------------------------------
// battle-api Worker — entry point.
//
// Chunk A1: minimal setup with a single /auth/test endpoint to verify
// the auth module works. Real routing (battle/create, etc.) is added
// in Chunk A3.
// ---------------------------------------------------------------------------

import type { Env } from './types.js';
import { verifyAuth } from './auth.js';
import { createBattle, joinBattle, startBattle, submitAnswer, nextQuestion, leaveBattle } from './routes/battle.js';
import { ApiError, jsonResponse, notFoundError } from './errors.js';

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    try {
      return await handleRequest(request, env);
    } catch (err: unknown) {
      // All known errors are ApiError instances with the { error, code } shape
      if (err instanceof ApiError) {
        return err.toResponse();
      }

      // Unexpected errors — log and return a generic 500
      console.error('Unhandled error:', err);
      return jsonResponse(
        { error: 'Internal server error', code: 'internal_error' },
        500,
      );
    }
  },
  async scheduled(event: ScheduledEvent, env: Env, ctx: ExecutionContext) {
    const { runCronSweep } = await import('./cron.js');
    ctx.waitUntil(runCronSweep(env));
  }
};

async function handleRequest(request: Request, env: Env): Promise<Response> {
  const url = new URL(request.url);
  const { pathname } = url;

  // --- CORS preflight (needed for Flutter web, harmless for mobile) ---
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: corsHeaders(),
    });
  }

  // --- Temporary auth test endpoint (Chunk A1 only) ---
  if (request.method === 'GET' && pathname === '/auth/test') {
    const { uid } = await verifyAuth(request, env);
    return withCors(jsonResponse({ ok: true, uid }));
  }

  // --- Battle Endpoints (Chunk A3) ---
  if (request.method === 'POST' && pathname === '/battle/create') {
    return withCors(await createBattle(request, env));
  }
  if (request.method === 'POST' && pathname === '/battle/join') {
    return withCors(await joinBattle(request, env));
  }
  if (request.method === 'POST' && pathname === '/battle/start') {
    return withCors(await startBattle(request, env));
  }
  if (request.method === 'POST' && pathname === '/battle/answer') {
    return withCors(await submitAnswer(request, env));
  }
  if (request.method === 'POST' && pathname === '/battle/next-question') {
    return withCors(await nextQuestion(request, env));
  }
  if (request.method === 'POST' && pathname === '/battle/leave') {
    return withCors(await leaveBattle(request, env));
  }

  // --- Health check (no auth required) ---
  if (request.method === 'GET' && pathname === '/health') {
    return withCors(jsonResponse({ status: 'ok', worker: 'battle-api' }));
  }

  throw notFoundError('Endpoint not found');
}

// ---------------------------------------------------------------------------
// CORS helpers
// ---------------------------------------------------------------------------

function corsHeaders(): HeadersInit {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
  };
}

/** Wrap an existing Response with CORS headers. */
function withCors(response: Response): Response {
  const headers = new Headers(response.headers);
  for (const [key, value] of Object.entries(corsHeaders())) {
    headers.set(key, value);
  }
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}
