import type { Env } from '../types.js';
import { verifyAuth } from '../auth.js';
import { getDoc, setDoc, runTransaction, serverTimestamp, runQuery } from '../firestore/index.js';
import {
  invalidConfigError,
  notFoundError,
  alreadyStartedError,
  alreadyJoinedError,
  fullError,
  internalError,
  notHostError,
  notEnoughPlayersError,
  alreadyAnsweredError,
} from '../errors.js';
import { computeScore } from '../scoring.js';
import { finalizeBattle } from './finalize.js';
import { checkRateLimit } from '../rateLimit.js';

const CODE_ALPHABET = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
const CODE_LENGTH = 6;

function generateCode(): string {
  let code = '';
  for (let i = 0; i < CODE_LENGTH; i++) {
    const randomIndex = Math.floor(Math.random() * CODE_ALPHABET.length);
    code += CODE_ALPHABET[randomIndex];
  }
  return code;
}

export async function createBattle(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
  const { uid } = await verifyAuth(request, env);

  let body: any;
  try {
    body = await request.json();
  } catch {
    throw invalidConfigError('Invalid JSON body');
  }

  const { topicId, questionCount, timeLimitSeconds, maxPlayers = 2 } = body;

  if (!topicId || typeof topicId !== 'string') {
    throw invalidConfigError('Missing or invalid topicId');
  }
  if (typeof questionCount !== 'number' || questionCount <= 0) {
    throw invalidConfigError('Invalid questionCount');
  }
  if (typeof timeLimitSeconds !== 'number' || timeLimitSeconds < 30 || timeLimitSeconds > 900) {
    throw invalidConfigError('timeLimitSeconds must be between 30 and 900');
  }
  if (typeof maxPlayers !== 'number' || maxPlayers < 2) {
    throw invalidConfigError('maxPlayers must be at least 2');
  }

  // 1. Verify Topic
  const topicDoc = await getDoc(env, `topics/${topicId}`);
  if (!topicDoc) {
    throw invalidConfigError('Topic not found');
  }

  // 1b. Check Rate Limit (5 creates per 10 mins)
  await checkRateLimit(env, `rl:create:${uid}`, 5, 10 * 60 * 1000);

  if (topicDoc.isActive !== true) {
    throw invalidConfigError('Topic is not active');
  }
  if ((topicDoc.questionCount ?? 0) < questionCount) {
    throw invalidConfigError(`Topic only has ${topicDoc.questionCount ?? 0} active questions`);
  }

  // 2. Generate a unique code using KV
  let code = '';
  let attempts = 0;
  const maxAttempts = 5;
  while (attempts < maxAttempts) {
    const candidate = generateCode();
    const existing = await env.BATTLE_CODES.get(candidate);
    if (!existing) {
      code = candidate;
      // Reserve it for 24 hours
      await env.BATTLE_CODES.put(code, 'reserved', { expirationTtl: 86400 });
      break;
    }
    attempts++;
  }

  if (!code) {
    throw internalError('Failed to generate a unique battle code');
  }

  // 3. Get user name and photo
  const userDoc = await getDoc(env, `users/${uid}`);
  const userName = userDoc?.name || 'Unknown Player';
  const userPhoto = userDoc?.photoUrl || '';

  // 4. Create the battle in Firestore
  const battleData = {
    hostUid: uid,
    topicId,
    questionCount,
    timeLimitSeconds,
    maxPlayers,
    status: 'waiting',
    playerUids: [uid],
    players: {
      [uid]: { name: userName, photoUrl: userPhoto },
    },
    readyUids: [],
    createdAt: serverTimestamp(),
  };

  ctx.waitUntil(setDoc(env, `battles/${code}`, battleData));

  return new Response(JSON.stringify({ ok: true, code }), {
    status: 200,
    headers: { 'content-type': 'application/json' },
  });
}

export async function joinBattle(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
  const { uid } = await verifyAuth(request, env);

  let body: any;
  try {
    body = await request.json();
  } catch {
    throw invalidConfigError('Invalid JSON body');
  }

  const { code } = body;
  if (!code || typeof code !== 'string') {
    throw invalidConfigError('Missing or invalid battle code');
  }

  // 1. Check Rate Limit (10 joins per 10 mins)
  await checkRateLimit(env, `rl:join:${uid}`, 10, 10 * 60 * 1000);

  // 2. Fetch the battle doc inside a transaction to prevent race conditions
  await runTransaction(env, async (tx) => {
    const battle = await tx.get(`battles/${code}`);
    
    if (!battle) {
      throw notFoundError('Battle not found');
    }

    if (battle.status !== 'waiting') {
      throw alreadyStartedError('Battle has already started or finished');
    }

    const playerUids: string[] = battle.playerUids || [];
    
    if (playerUids.includes(uid)) {
      throw alreadyJoinedError('You have already joined this battle');
    }

    const maxPlayers = battle.maxPlayers ?? 2;
    if (playerUids.length >= maxPlayers) {
      throw fullError('Battle is full');
    }

    // Fetch user name and photo
    const userDoc = await tx.get(`users/${uid}`);
    const userName = userDoc?.name || 'Unknown Player';
    const userPhoto = userDoc?.photoUrl || '';

    // Add player and update
    playerUids.push(uid);
    const players = battle.players || {};
    players[uid] = { name: userName, photoUrl: userPhoto };
    
    tx.update(`battles/${code}`, { playerUids, players });
  });

  // 4. Stub FCM notification
  console.log(`[FCM Stub]: Notifying lobby that user ${uid} joined battle ${code}`);

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { 'content-type': 'application/json' },
  });
}

// ---------------------------------------------------------------------------
// Chunk A3.5 — battle/toggle-ready
// ---------------------------------------------------------------------------

export async function toggleReady(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
  const { uid } = await verifyAuth(request, env);

  let body: any;
  try {
    body = await request.json();
  } catch {
    throw invalidConfigError('Invalid JSON body');
  }

  const { code, isReady } = body;
  if (!code || typeof code !== 'string') {
    throw invalidConfigError('Missing or invalid battle code');
  }
  if (typeof isReady !== 'boolean') {
    throw invalidConfigError('isReady must be a boolean');
  }

  await runTransaction(env, async (tx) => {
    const battle = await tx.get(`battles/${code}`);
    if (!battle) throw notFoundError('Battle not found');
    if (battle.status !== 'waiting') throw alreadyStartedError('Battle has already started or finished');
    
    const playerUids: string[] = battle.playerUids || [];
    if (!playerUids.includes(uid)) throw invalidConfigError('You are not in this battle');

    let readyUids: string[] = battle.readyUids || [];
    if (isReady && !readyUids.includes(uid)) {
      readyUids.push(uid);
    } else if (!isReady && readyUids.includes(uid)) {
      readyUids = readyUids.filter(id => id !== uid);
    }

    tx.update(`battles/${code}`, { readyUids });
  });

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { 'content-type': 'application/json' },
  });
}

// ---------------------------------------------------------------------------
// Chunk A4 — battle/start
// ---------------------------------------------------------------------------

export async function startBattle(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
  const { uid } = await verifyAuth(request, env);

  let body: any;
  try {
    body = await request.json();
  } catch {
    throw invalidConfigError('Invalid JSON body');
  }

  const { code } = body;
  if (!code || typeof code !== 'string') {
    throw invalidConfigError('Missing or invalid battle code');
  }

  // 1. Fast read (non-transaction) to check host and topic
  const battle = await getDoc(env, `battles/${code}`);
  if (!battle) {
    throw notFoundError('Battle not found');
  }
  if (battle.hostUid !== uid) {
    throw notHostError('Only the host can start the battle');
  }
  if (battle.status !== 'waiting') {
    throw alreadyStartedError('Battle has already started or finished');
  }
  
  const playerUids: string[] = battle.playerUids || [];
  const readyUids: string[] = battle.readyUids || [];
  if (playerUids.length < 2) {
    throw notEnoughPlayersError('At least 2 players are required to start the battle');
  }
  
  // Verify everyone is ready
  if (readyUids.length !== playerUids.length) {
    throw invalidConfigError('Not all players are ready');
  }


  // 2. Fetch active question IDs from topic
  const structuredQuery = {
    select: { fields: [{ fieldPath: '__name__' }] },
    from: [{ collectionId: 'questions' }],
    where: {
      fieldFilter: {
        field: { fieldPath: 'isActive' },
        op: 'EQUAL',
        value: { booleanValue: true },
      },
    },
  };

  const questionDocs = await runQuery(env, `topics/${battle.topicId}`, structuredQuery);
  const activeIds = questionDocs.map((doc: any) => doc.name.split('/').pop() as string);

  if (activeIds.length === 0) {
    throw invalidConfigError(`No active questions available for this topic.`);
  }

  // Automatically reduce question count if not enough
  let finalQuestionCount = battle.questionCount;
  if (activeIds.length < finalQuestionCount) {
    finalQuestionCount = activeIds.length;
  }

  // 3. Shuffle and pick random questions
  // Fisher-Yates shuffle
  for (let i = activeIds.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    const temp = activeIds[i]!;
    activeIds[i] = activeIds[j]!;
    activeIds[j] = temp;
  }
  const selectedQuestionIds = activeIds.slice(0, finalQuestionCount);

  // 4. Start the battle via transaction in the background for faster response
  const backgroundWork = (async () => {
    try {
      let finalQuestionsData: any[] = [];
      await runTransaction(env, async (tx) => {
        const latestBattle = await tx.get(`battles/${code}`);
        if (!latestBattle) throw notFoundError('Battle not found');
        if (latestBattle.status !== 'waiting') throw alreadyStartedError('Battle has already started or finished');
        
        const playerUids: string[] = latestBattle.playerUids || [];
        const readyUids: string[] = latestBattle.readyUids || [];
        if (playerUids.length < 2) throw notEnoughPlayersError('At least 2 players are required to start the battle');
        if (readyUids.length !== playerUids.length) throw invalidConfigError('Not all players are ready');

        // Fetch full data for all selected questions
        const questionsData = [];
        for (const qId of selectedQuestionIds) {
          const qDoc = await tx.get(`topics/${latestBattle.topicId}/questions/${qId}`);
          if (qDoc) {
            questionsData.push({
              id: qId,
              text: qDoc.text || qDoc.textBn || qDoc.textEn,
              options: qDoc.options || qDoc.optionsBn || qDoc.optionsEn,
              difficulty: qDoc.difficulty,
              correctIndex: qDoc.correctIndex,
              points: qDoc.points || 10,
              explanation: qDoc.explanation,
              sourceType: qDoc.sourceType,
              sourceReference: qDoc.sourceReference,
            });
          }
        }

        tx.update(`battles/${code}`, {
          status: 'active',
          questionCount: finalQuestionCount,
          questionIds: selectedQuestionIds,
          startedAt: serverTimestamp(),
        });
        
        finalQuestionsData = questionsData;
      });

      // Save to KV with 2 hour expiration
      await env.BATTLE_CODES.put(`questions_${code}`, JSON.stringify(finalQuestionsData), { expirationTtl: 7200 });
      console.log(`[startBattle] Background work completed for ${code}`);
    } catch (e) {
      console.error(`[startBattle] Background work failed for ${code}:`, e);
    }
  })();
  
  ctx.waitUntil(backgroundWork);

  // 5. FCM Notification stub
  console.log(`[FCM Stub]: Notifying lobby that battle ${code} is starting!`);

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { 'content-type': 'application/json' },
  });
}

// ---------------------------------------------------------------------------
// Chunk A5 — battle/answer & battle/next-question
// ---------------------------------------------------------------------------

export async function submitAllAnswers(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
  const { uid } = await verifyAuth(request, env);

  let body: any;
  try {
    body = await request.json();
  } catch {
    throw invalidConfigError('Invalid JSON body');
  }

  const { code, answers } = body;
  if (!code || typeof code !== 'string') {
    throw invalidConfigError('Missing battle code');
  }
  if (!Array.isArray(answers)) {
    throw invalidConfigError('answers must be an array');
  }

  // Fetch questionsData from KV since it was moved out of Firestore
  const questionsJson = await env.BATTLE_CODES.get(`questions_${code}`);
  let questionsData: any[] = [];
  if (questionsJson) {
    try {
      questionsData = JSON.parse(questionsJson);
    } catch (e) {
      console.error('Failed to parse questionsData from KV', e);
    }
  }

  const backgroundWork = (async () => {
    try {
      await runTransaction(env, async (tx) => {
        const battle = await tx.get(`battles/${code}`);
        if (!battle) throw notFoundError('Battle not found');
        if (battle.status !== 'active') throw invalidConfigError('Battle is not active');
        
        const playerUids: string[] = battle.playerUids || [];
        if (!playerUids.includes(uid)) throw invalidConfigError('You are not in this battle');

        // Make sure user hasn't already submitted
        const scoreboard = await tx.get(`battles/${code}/scoreboard/live`) || {};
        const playerStats = scoreboard[uid] || { score: 0, totalTimeMs: 0, correctCount: 0, hasFinished: false };
        
        if (playerStats.hasFinished) {
          throw alreadyAnsweredError('You have already submitted your final answers');
        }

        const startedAt = battle.startedAt ? new Date(battle.startedAt).getTime() : Date.now();
        const maxTimeSeconds = battle.timeLimitSeconds ?? 300;
        const timeLimitMs = maxTimeSeconds * 1000;
        
        // Validate if the battle time limit expired massively (allow 10 seconds grace period for network)
        const timeSinceStartMs = Date.now() - startedAt;
        if (timeSinceStartMs > timeLimitMs + 10000) {
          console.log(`User ${uid} submitted late, but we will accept whatever answers they made in time.`);
        }

        // questionsData is captured from the outer scope
        let totalScore = 0;
        let totalResponseTimeMs = 0;
        let totalCorrect = 0;
        const evaluatedAnswers: any[] = [];

        // Process each answer
        for (const ans of answers) {
          const qId = ans.questionId;
          const selectedIndex = ans.selectedIndex;
          const responseTimeMs = ans.responseTimeMs || 0;

          const qData = questionsData.find((q: any) => q.id === qId);
          if (!qData) continue; // Skip invalid question ids
          
          const correctIndex = qData.correctIndex ?? 0;
          const basePoints = qData.points ?? 10;
          
          const computed = computeScore(selectedIndex === correctIndex, basePoints, responseTimeMs, 15000); // base scoring on 15s per question
          
          const isCorrect = computed.isCorrect;
          const pointsAwarded = computed.pointsAwarded;

          totalScore += pointsAwarded;
          totalResponseTimeMs += responseTimeMs;
          if (isCorrect) totalCorrect += 1;

          evaluatedAnswers.push({
            questionId: qId,
            selectedIndex,
            responseTimeMs,
            isCorrect,
            pointsAwarded,
          });

          // Write answer (optional, for history)
          tx.set(`battles/${code}/answers/${uid}_${qId}`, {
            uid,
            questionId: qId,
            selectedIndex,
            responseTimeMs,
            isCorrect,
            pointsAwarded,
            createdAt: serverTimestamp(),
          });
        }

        // Update scoreboard
        playerStats.score = totalScore;
        playerStats.totalTimeMs = totalResponseTimeMs;
        playerStats.correctCount = totalCorrect;
        playerStats.hasFinished = true;
        playerStats.answers = evaluatedAnswers;

        scoreboard[uid] = playerStats;
        tx.set(`battles/${code}/scoreboard/live`, scoreboard);

        // Check if ALL players have finished
        const allFinished = playerUids.every(pId => scoreboard[pId]?.hasFinished === true);

        if (allFinished) {
          await finalizeBattle(tx, code, battle, scoreboard, questionsData);
        }
      });
      console.log(`[submitAllAnswers] Background work completed for ${code}, user: ${uid}`);
    } catch (e) {
      console.error(`[submitAllAnswers] Background work failed for ${code}, user: ${uid}:`, e);
    }
  })();

  ctx.waitUntil(backgroundWork);

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { 'content-type': 'application/json' },
  });
}

// ---------------------------------------------------------------------------
// Chunk A6 — battle/leave
// ---------------------------------------------------------------------------

export async function leaveBattle(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
  const { uid } = await verifyAuth(request, env);

  let body: any;
  try {
    body = await request.json();
  } catch {
    throw invalidConfigError('Invalid JSON body');
  }

  const { code } = body;
  if (!code || typeof code !== 'string') {
    throw invalidConfigError('Missing battle code');
  }

  // Fetch questionsData from KV for finalizeBattle
  const questionsJson = await env.BATTLE_CODES.get(`questions_${code}`);
  let questionsData: any[] = [];
  if (questionsJson) {
    try {
      questionsData = JSON.parse(questionsJson);
    } catch (e) {
      console.error('Failed to parse questionsData from KV', e);
    }
  }

  await runTransaction(env, async (tx) => {
    const battle = await tx.get(`battles/${code}`);
    if (!battle) throw notFoundError('Battle not found');

    const playerUids: string[] = battle.playerUids || [];
    if (!playerUids.includes(uid)) {
      // Already not in battle
      return;
    }

    if (battle.status === 'waiting') {
      const newUids = playerUids.filter((p) => p !== uid);
      if (newUids.length === 0 || uid === battle.hostUid) {
        // Cancel battle if empty OR if the host left
        tx.update(`battles/${code}`, {
          status: 'cancelled',
          playerUids: [],
          readyUids: [],
        });
        // Release code from KV
        await env.BATTLE_CODES.delete(code);
      } else {
        // Just remove the player from ready list and player list
        const newReadyUids = (battle.readyUids || []).filter((p: string) => p !== uid);
        
        tx.update(`battles/${code}`, {
          playerUids: newUids,
          readyUids: newReadyUids,
        });
      }
    } else if (battle.status === 'active') {
      const forfeitedUids: string[] = battle.forfeitedUids || [];
      if (!forfeitedUids.includes(uid)) {
        forfeitedUids.push(uid);
      }
      
      const activePlayers = playerUids.filter(p => !forfeitedUids.includes(p));
      
      if (activePlayers.length <= 1) {
        // Only 1 player remains, finalize immediately
        const winnerUid = activePlayers.length === 1 ? activePlayers[0] : null;
        const scoreboard = await tx.get(`battles/${code}/scoreboard/live`) || {};
        await finalizeBattle(tx, code, battle, scoreboard, questionsData, winnerUid ?? undefined);
      } else {
        // Just mark as forfeited
        tx.update(`battles/${code}`, {
          forfeitedUids,
        });
      }
    } else {
      throw invalidConfigError('Cannot leave a finished or cancelled battle');
    }
  });

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { 'content-type': 'application/json' },
  });
}

// ---------------------------------------------------------------------------
// Chunk A7 — getBattleQuestions
// ---------------------------------------------------------------------------
export async function getBattleQuestions(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
  const url = new URL(request.url);
  const parts = url.pathname.split('/');
  const code = parts.length >= 3 ? parts[parts.length - 2] : null;
  
  if (!code) {
    throw invalidConfigError('Missing battle code');
  }

  // The client must be authenticated to fetch questions
  await verifyAuth(request, env);

  const questionsJson = await env.BATTLE_CODES.get(`questions_${code}`);
  if (!questionsJson) {
    throw notFoundError('Questions not found or expired');
  }

  return new Response(questionsJson, {
    status: 200,
    headers: { 'content-type': 'application/json' },
  });
}
