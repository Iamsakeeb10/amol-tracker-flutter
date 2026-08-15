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

export async function createBattle(request: Request, env: Env): Promise<Response> {
  const { uid } = await verifyAuth(request, env);

  let body: any;
  try {
    body = await request.json();
  } catch {
    throw invalidConfigError('Invalid JSON body');
  }

  const { topicId, questionCount, secondsPerQuestion, maxPlayers = 2 } = body;

  if (!topicId || typeof topicId !== 'string') {
    throw invalidConfigError('Missing or invalid topicId');
  }
  if (typeof questionCount !== 'number' || questionCount <= 0) {
    throw invalidConfigError('Invalid questionCount');
  }
  if (typeof secondsPerQuestion !== 'number' || secondsPerQuestion < 5 || secondsPerQuestion > 60) {
    throw invalidConfigError('secondsPerQuestion must be between 5 and 60');
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

  // 3. Create the battle in Firestore
  const battleData = {
    hostUid: uid,
    topicId,
    questionCount,
    secondsPerQuestion,
    maxPlayers,
    status: 'waiting',
    playerUids: [uid],
    readyUids: [],
    createdAt: serverTimestamp(),
  };

  await setDoc(env, `battles/${code}`, battleData);

  return new Response(JSON.stringify({ ok: true, code }), {
    status: 200,
    headers: { 'content-type': 'application/json' },
  });
}

export async function joinBattle(request: Request, env: Env): Promise<Response> {
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

    // Add player and update
    playerUids.push(uid);
    tx.update(`battles/${code}`, { playerUids });
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

export async function toggleReady(request: Request, env: Env): Promise<Response> {
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

export async function startBattle(request: Request, env: Env): Promise<Response> {
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

  if (activeIds.length < battle.questionCount) {
    throw invalidConfigError(`Not enough active questions. Requested ${battle.questionCount}, but only ${activeIds.length} available.`);
  }

  // 3. Shuffle and pick random questions
  // Fisher-Yates shuffle
  for (let i = activeIds.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    const temp = activeIds[i]!;
    activeIds[i] = activeIds[j]!;
    activeIds[j] = temp;
  }
  const selectedQuestionIds = activeIds.slice(0, battle.questionCount);

  // 4. Start the battle via transaction
  await runTransaction(env, async (tx) => {
    const latestBattle = await tx.get(`battles/${code}`);
    if (!latestBattle) {
      throw notFoundError('Battle not found');
    }
    if (latestBattle.status !== 'waiting') {
      throw alreadyStartedError('Battle has already started or finished');
    }
    
    const playerUids: string[] = latestBattle.playerUids || [];
    const readyUids: string[] = latestBattle.readyUids || [];
    if (playerUids.length < 2) {
      throw notEnoughPlayersError('At least 2 players are required to start the battle');
    }
    if (readyUids.length !== playerUids.length) {
      throw invalidConfigError('Not all players are ready');
    }

    const firstQuestion = await tx.get(`topics/${latestBattle.topicId}/questions/${selectedQuestionIds[0]}`);
    let currentQuestionData = null;
    if (firstQuestion) {
      currentQuestionData = {
        id: selectedQuestionIds[0],
        text: firstQuestion.text || firstQuestion.textBn || firstQuestion.textEn,
        options: firstQuestion.options || firstQuestion.optionsBn || firstQuestion.optionsEn,
        difficulty: firstQuestion.difficulty,
      };
    }

    tx.update(`battles/${code}`, {
      status: 'active',
      questionIds: selectedQuestionIds,
      currentQuestionIndex: 0,
      questionRevealedAt: serverTimestamp(),
      currentQuestion: currentQuestionData,
      revealedAnswers: {},
    });
  });

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

export async function submitAnswer(request: Request, env: Env): Promise<Response> {
  const { uid } = await verifyAuth(request, env);

  let body: any;
  try {
    body = await request.json();
  } catch {
    throw invalidConfigError('Invalid JSON body');
  }

  const { code, selectedIndex, responseTimeMs } = body;
  if (!code || typeof code !== 'string') {
    throw invalidConfigError('Missing battle code');
  }
  if (typeof selectedIndex !== 'number' && selectedIndex !== null) {
    throw invalidConfigError('Invalid selectedIndex');
  }
  if (typeof responseTimeMs !== 'number' || responseTimeMs < 0) {
    throw invalidConfigError('Invalid responseTimeMs');
  }

  let isCorrect = false;
  let pointsAwarded = 0;

  await runTransaction(env, async (tx) => {
    const battle = await tx.get(`battles/${code}`);
    if (!battle) throw notFoundError('Battle not found');
    if (battle.status !== 'active') throw invalidConfigError('Battle is not active');
    
    const playerUids: string[] = battle.playerUids || [];
    if (!playerUids.includes(uid)) throw invalidConfigError('You are not in this battle');

    const currentIndex = battle.currentQuestionIndex ?? 0;
    const questionIds: string[] = battle.questionIds || [];
    const questionId = questionIds[currentIndex];
    
    if (!questionId) throw internalError('No current question found');

    const revealedAt = battle.questionRevealedAt ? new Date(battle.questionRevealedAt).getTime() : Date.now();
    const maxTimeMs = (battle.secondsPerQuestion ?? 15) * 1000;
    
    // Check grace period
    if (Date.now() - revealedAt > maxTimeMs + 2000) {
      throw invalidConfigError('Time expired for this question');
    }

    // Check if already answered
    const answerDoc = await tx.get(`battles/${code}/answers/${uid}_${questionId}`);
    if (answerDoc) {
      throw alreadyAnsweredError();
    }

    // Fetch the question to check correct index and base points
    const question = await tx.get(`topics/${battle.topicId}/questions/${questionId}`);
    if (!question) throw internalError('Question not found');

    const correctIndex = question.correctIndex ?? 0;
    const basePoints = question.points ?? 10;

    const computed = computeScore(selectedIndex === correctIndex, basePoints, responseTimeMs, maxTimeMs);
    isCorrect = computed.isCorrect;
    pointsAwarded = computed.pointsAwarded;

    // Write answer
    tx.set(`battles/${code}/answers/${uid}_${questionId}`, {
      uid,
      questionId,
      selectedIndex,
      responseTimeMs,
      isCorrect,
      pointsAwarded,
      createdAt: serverTimestamp(),
    });

    // Update live scoreboard
    const scoreboard = await tx.get(`battles/${code}/scoreboard/live`);
    const playerStats = scoreboard?.[uid] || { score: 0, totalTimeMs: 0, correctCount: 0 };
    
    playerStats.score += pointsAwarded;
    playerStats.totalTimeMs += responseTimeMs;
    if (isCorrect) playerStats.correctCount += 1;

    // Set scoreboard with the updated user entry
    tx.set(`battles/${code}/scoreboard/live`, {
      ...scoreboard,
      [uid]: playerStats,
    });
  });

  return new Response(JSON.stringify({ ok: true, isCorrect, pointsAwarded }), {
    status: 200,
    headers: { 'content-type': 'application/json' },
  });
}

export async function nextQuestion(request: Request, env: Env): Promise<Response> {
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

  let responsePayload: any = { ok: true };

  await runTransaction(env, async (tx) => {
    const battle = await tx.get(`battles/${code}`);
    if (!battle) throw notFoundError('Battle not found');
    if (battle.hostUid !== uid) throw notHostError('Only the host can advance the battle');
    if (battle.status !== 'active') throw invalidConfigError('Battle is not active');

    const maxTimeMs = (battle.secondsPerQuestion ?? 15) * 1000;
    const revealedAt = battle.questionRevealedAt ? new Date(battle.questionRevealedAt).getTime() : 0;
    
    // Plausibility check
    if (Date.now() - revealedAt < maxTimeMs - 5000) {
      throw invalidConfigError('Cannot advance question yet');
    }

    const currentIndex = battle.currentQuestionIndex ?? 0;
    const questionIds: string[] = battle.questionIds || [];
    
    // Fetch previous question to return answer
    const prevQ = await tx.get(`topics/${battle.topicId}/questions/${questionIds[currentIndex]}`);
    const newRevealedAnswers = battle.revealedAnswers || {};
    if (prevQ) {
      const prevAnswerData = {
        correctIndex: prevQ.correctIndex,
        explanationEn: prevQ.explanationEn,
        explanationBn: prevQ.explanationBn,
      };
      responsePayload.previousQuestion = prevAnswerData;
      newRevealedAnswers[questionIds[currentIndex]!] = prevAnswerData;
    }

    if (currentIndex >= questionIds.length - 1) {
      // LAST QUESTION: Finalize battle
      const scoreboard = await tx.get(`battles/${code}/scoreboard/live`) || {};
      
      // We still update the battle to reveal the last answer
      tx.update(`battles/${code}`, {
        revealedAnswers: newRevealedAnswers,
      });

      await finalizeBattle(tx, code, battle, scoreboard);
      responsePayload.isFinished = true;
    } else {
      // NEXT QUESTION
      const nextIndex = currentIndex + 1;

      const nextQ = await tx.get(`topics/${battle.topicId}/questions/${questionIds[nextIndex]}`);
      let currentQuestionData = null;
      if (nextQ) {
        currentQuestionData = {
          id: questionIds[nextIndex],
          text: nextQ.text || nextQ.textBn || nextQ.textEn,
          options: nextQ.options || nextQ.optionsBn || nextQ.optionsEn,
          difficulty: nextQ.difficulty,
        };
        responsePayload.nextQuestion = currentQuestionData;
      }

      tx.update(`battles/${code}`, {
        currentQuestionIndex: nextIndex,
        questionRevealedAt: serverTimestamp(),
        currentQuestion: currentQuestionData,
        revealedAnswers: newRevealedAnswers,
      });

      responsePayload.isFinished = false;
    }
  });

  return new Response(JSON.stringify(responsePayload), {
    status: 200,
    headers: { 'content-type': 'application/json' },
  });
}

// ---------------------------------------------------------------------------
// Chunk A6 — battle/leave
// ---------------------------------------------------------------------------

export async function leaveBattle(request: Request, env: Env): Promise<Response> {
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
      if (newUids.length === 0) {
        // Cancel battle
        tx.update(`battles/${code}`, {
          status: 'cancelled',
          playerUids: [],
          readyUids: [],
        });
        // Release code from KV
        await env.BATTLE_CODES.delete(code);
      } else {
        // Promote next joiner if host left
        const newHost = battle.hostUid === uid ? newUids[0] : battle.hostUid;
        
        // Remove from ready list if they were ready
        const newReadyUids = (battle.readyUids || []).filter((p: string) => p !== uid);
        
        tx.update(`battles/${code}`, {
          playerUids: newUids,
          hostUid: newHost,
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
        await finalizeBattle(tx, code, battle, scoreboard, winnerUid ?? undefined);
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
