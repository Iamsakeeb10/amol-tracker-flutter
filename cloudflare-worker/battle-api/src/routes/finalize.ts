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
  questionsData: any[],
  forcedWinnerUid?: string
): Promise<void> {
  const playerUids: string[] = battle.playerUids || [];
  
  // Create player array from scoreboard
  const players = playerUids.map((pUid) => ({
    uid: pUid,
    name: battle.players?.[pUid]?.name ?? 'Unknown Player',
    score: scoreboard[pUid]?.score ?? 0,
    totalTimeMs: scoreboard[pUid]?.totalTimeMs ?? 0,
    answers: scoreboard[pUid]?.answers ?? [],
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

  // Fetch all played questions from the provided array
  const playedQuestions = (questionsData || []).map((qData: any) => ({
    id: qData.id,
    text: qData.text,
    options: qData.options,
    correctIndex: qData.correctIndex,
    explanation: qData.explanation,
    reference: qData.reference,
    difficulty: qData.difficulty,
  }));

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
      const currentBattlePlays = userDoc.battlePlays ?? 0;
      const currentBattleWins = userDoc.battleWins ?? 0;
      const currentBattleScore = userDoc.battleScore ?? 0;
      
      const isWin = winnerUid === p.uid;
      tx.update(`users/${p.uid}`, { 
        lmsXp: newXp,
        battlePlays: currentBattlePlays + 1,
        battleWins: currentBattleWins + (isWin ? 1 : 0),
        battleScore: currentBattleScore + p.score,
      });
    }

    // Write battle history
    const opponents = players
      .filter(x => x.uid !== p.uid)
      .map(x => ({ uid: x.uid, name: x.name }));
      
    let result = 'loss';
    if (winnerUid === null) {
      result = 'draw';
    } else if (winnerUid === p.uid) {
      result = 'win';
    }

    tx.set(`users/${p.uid}/battleHistory/${code}`, {
      battleId: code,
      opponents,
      topicId: battle.topicId,
      result,
      score: p.score,
      date: serverTimestamp(),
    });
  }
}
