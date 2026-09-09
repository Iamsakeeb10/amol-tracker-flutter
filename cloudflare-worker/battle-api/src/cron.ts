import type { Env } from './types.js';
import { runQuery, runTransaction } from './firestore/index.js';
import { decodeDocument } from './firestore/mapper.js';
import { finalizeBattle } from './routes/finalize.js';

/** Max allowed battle duration from createBattle validation (900s) plus 60s grace. */
const MAX_ACTIVE_BATTLE_MS = 15 * 60 * 1000 + 60_000;
/** Waiting lobbies expire after this duration. */
const WAITING_EXPIRY_MS = 5 * 60 * 1000;
/** Safety cap so a single cron run cannot scan unbounded docs. */
const QUERY_LIMIT = 50;

/**
 * Runs periodically (every 5 minutes) to clean up stale battles.
 * Queries only battles old enough to need cleanup to minimize Firestore reads.
 */
export async function runCronSweep(env: Env): Promise<void> {
  const now = Date.now();
  console.log('[Cron] Starting sweep at', new Date(now).toISOString());

  // 1. Fetch WAITING battles older than 5 minutes (already expired candidates)
  const fiveMinutesAgo = new Date(now - WAITING_EXPIRY_MS).toISOString();
  const waitingQuery = {
    from: [{ collectionId: 'battles' }],
    where: {
      compositeFilter: {
        op: 'AND',
        filters: [
          {
            fieldFilter: {
              field: { fieldPath: 'status' },
              op: 'EQUAL',
              value: { stringValue: 'waiting' },
            },
          },
          {
            fieldFilter: {
              field: { fieldPath: 'createdAt' },
              op: 'LESS_THAN',
              value: { timestampValue: fiveMinutesAgo },
            },
          },
        ],
      },
    },
    limit: QUERY_LIMIT,
  };
  const waitingDocs = await runQuery(env, '', waitingQuery);

  for (const doc of waitingDocs) {
    const battle = decodeDocument(doc.fields);
    const code = doc.name.split('/').pop() as string;
    const createdAtRaw = battle.createdAt;
    if (!createdAtRaw) continue;

    const createdAt = new Date(createdAtRaw).getTime();
    if (now - createdAt > WAITING_EXPIRY_MS) {
      console.log(`[Cron] Expiring waiting battle ${code}`);
      await runTransaction(env, async (tx) => {
        const latest = await tx.get(`battles/${code}`);
        if (latest && latest.status === 'waiting') {
          tx.update(`battles/${code}`, {
            status: 'expired',
            playerUids: [],
          });
          await env.BATTLE_CODES.delete(code);
        }
      });
    }
  }

  // 2. Fetch ACTIVE battles that have exceeded the maximum possible duration
  // (15 min timeLimit + 60s grace). Per-battle timeLimit is still checked below.
  const cutoffTime = new Date(now - MAX_ACTIVE_BATTLE_MS).toISOString();
  const activeQuery = {
    from: [{ collectionId: 'battles' }],
    where: {
      compositeFilter: {
        op: 'AND',
        filters: [
          {
            fieldFilter: {
              field: { fieldPath: 'status' },
              op: 'EQUAL',
              value: { stringValue: 'active' },
            },
          },
          {
            fieldFilter: {
              field: { fieldPath: 'startedAt' },
              op: 'LESS_THAN',
              value: { timestampValue: cutoffTime },
            },
          },
        ],
      },
    },
    limit: QUERY_LIMIT,
  };
  const activeDocs = await runQuery(env, '', activeQuery);

  for (const doc of activeDocs) {
    const battle = decodeDocument(doc.fields);
    const code = doc.name.split('/').pop() as string;
    const startedAtRaw = battle.startedAt;
    if (!startedAtRaw) continue;

    const startedAt = new Date(startedAtRaw).getTime();
    const maxTimeMs = (battle.timeLimitSeconds ?? 300) * 1000;

    // timeLimitSeconds + 60s grace period for network latency and submission
    if (now - startedAt > maxTimeMs + 60_000) {
      console.log(`[Cron] Force-finalizing active battle ${code}`);

      const questionsJson = await env.BATTLE_CODES.get(`questions_${code}`);
      let questionsData: any[] = [];
      if (questionsJson) {
        try {
          questionsData = JSON.parse(questionsJson);
        } catch (e) {}
      }

      await runTransaction(env, async (tx) => {
        const latest = await tx.get(`battles/${code}`);
        if (latest && latest.status === 'active') {
          // Force finalize it with whatever they submitted
          const scoreboard = (await tx.get(`battles/${code}/scoreboard/live`)) || {};
          await finalizeBattle(tx, code, latest, scoreboard, questionsData);
        }
      });
    }
  }

  console.log('[Cron] Sweep finished.');
}
