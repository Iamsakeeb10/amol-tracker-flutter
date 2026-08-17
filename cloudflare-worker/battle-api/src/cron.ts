import type { Env } from './types.js';
import { runQuery, runTransaction } from './firestore/index.js';
import { finalizeBattle } from './routes/finalize.js';

/**
 * Runs periodically (e.g. every minute) to clean up stale battles.
 */
export async function runCronSweep(env: Env): Promise<void> {
  const now = Date.now();
  console.log('[Cron] Starting sweep at', new Date(now).toISOString());

  // 1. Fetch WAITING battles
  // (Filter in memory to avoid needing composite Firestore indexes for status + createdAt)
  const waitingQuery = {
    from: [{ collectionId: 'battles' }],
    where: {
      fieldFilter: {
        field: { fieldPath: 'status' },
        op: 'EQUAL',
        value: { stringValue: 'waiting' },
      },
    },
  };
  const waitingDocs = await runQuery(env, '', waitingQuery);
  
  for (const doc of waitingDocs) {
    const battle = doc.fields;
    const code = doc.name.split('/').pop() as string;
    const createdAtStr = battle.createdAt; // ISO string from mapper
    if (!createdAtStr) continue;

    const createdAt = new Date(createdAtStr).getTime();
    if (now - createdAt > 5 * 60 * 1000) {
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

  // 2. Fetch ACTIVE battles
  const activeQuery = {
    from: [{ collectionId: 'battles' }],
    where: {
      fieldFilter: {
        field: { fieldPath: 'status' },
        op: 'EQUAL',
        value: { stringValue: 'active' },
      },
    },
  };
  const activeDocs = await runQuery(env, '', activeQuery);

  for (const doc of activeDocs) {
    const battle = doc.fields;
    const code = doc.name.split('/').pop() as string;
    const startedAtStr = battle.startedAt;
    if (!startedAtStr) continue;

    const startedAt = new Date(startedAtStr).getTime();
    const maxTimeMs = (battle.timeLimitSeconds ?? 300) * 1000;
    
    // timeLimitSeconds + 60s grace period for network latency and submission
    if (now - startedAt > maxTimeMs + 60000) {
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
          const scoreboard = await tx.get(`battles/${code}/scoreboard/live`) || {};
          await finalizeBattle(tx, code, latest, scoreboard, questionsData);
        }
      });
    }
  }

  console.log('[Cron] Sweep finished.');
}
