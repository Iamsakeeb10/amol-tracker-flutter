import { serverTimestamp } from '../firestore/index.js';
import type { Transaction } from '../firestore/index.js';

/**
 * Common logic to finalize a battle.
 * Computes scores, sets the winner, updates battleResults, xp, and battleHistory.
 */
export async function finalizeBattle(
  tx: Transaction,
  code: string,
  battle: any,
  scoreboard: Record<string, any>,
  forcedWinnerUid?: string
): Promise<void> {
  const playerUids: string[] = battle.playerUids || [];
  
  // Create player array from scoreboard
  const players = playerUids.map((pUid) => ({
    uid: pUid,
    score: scoreboard[pUid]?.score ?? 0,
    totalTimeMs: scoreboard[pUid]?.totalTimeMs ?? 0,
  }));

  // Sort by score DESC, then time ASC
  players.sort((a, b) => {
    if (b.score !== a.score) return b.score - a.score;
    return a.totalTimeMs - b.totalTimeMs;
  });

  let winnerUid: string | null = null;
  if (forcedWinnerUid !== undefined) {
    winnerUid = forcedWinnerUid;
  } else if (players.length > 0) {
    const p1 = players[0]!;
    const p2 = players[1];
    if (players.length > 1 && p2 && p1.score === p2.score && p1.totalTimeMs === p2.totalTimeMs) {
      winnerUid = null; // true tie
    } else {
      winnerUid = p1.uid;
    }
  }

  // Fetch all played questions
  const questionIds: string[] = battle.questionIds || [];
  const playedQuestions = [];
  for (let i = 0; i <= (battle.currentQuestionIndex ?? 0); i++) {
    if (i < questionIds.length) {
      const qId = questionIds[i]!;
      const qDoc = await tx.get(`topics/${battle.topicId}/questions/${qId}`);
      if (qDoc) {
        playedQuestions.push({
          id: qId,
          textEn: qDoc.textEn,
          textBn: qDoc.textBn,
          optionsEn: qDoc.optionsEn,
          optionsBn: qDoc.optionsBn,
          correctIndex: qDoc.correctIndex,
          explanationEn: qDoc.explanationEn,
          explanationBn: qDoc.explanationBn,
          referenceEn: qDoc.referenceEn,
          referenceBn: qDoc.referenceBn,
          difficulty: qDoc.difficulty,
        });
      }
    }
  }

  // Update battle document
  tx.update(`battles/${code}`, {
    status: 'finished',
    winnerUid,
  });

  // Write battle result record
  tx.set(`battleResults/${code}`, {
    players,
    winnerUid,
    finishedAt: serverTimestamp(),
    topicId: battle.topicId,
    questions: playedQuestions,
  });

  // Update XP and History for each player
  for (const p of players) {
    // Read User doc
    const userDoc = await tx.get(`users/${p.uid}`);
    if (userDoc) {
      const newXp = (userDoc.lmsXp ?? 0) + p.score;
      tx.update(`users/${p.uid}`, { lmsXp: newXp });
    }

    // Write battle history
    const opponentUids = players.map(x => x.uid).filter(id => id !== p.uid);
    let result = 'loss';
    if (winnerUid === null) {
      result = 'draw';
    } else if (winnerUid === p.uid) {
      result = 'win';
    }

    tx.set(`users/${p.uid}/battleHistory/${code}`, {
      battleId: code,
      opponentUids,
      topicId: battle.topicId,
      result,
      score: p.score,
      date: serverTimestamp(),
    });
  }
}
