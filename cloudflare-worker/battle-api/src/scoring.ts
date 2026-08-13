/**
 * Computes points awarded based on correctness and speed.
 * 
 * Rules:
 * - Wrong or skipped answers give 0 points.
 * - Correct answers give a minimum of basePoints.
 * - Fast answers give up to 50% extra points (linearly scaled by responseTime).
 * - All math is rounded to integers.
 * 
 * @param isCorrect Whether the chosen index matches the correct index.
 * @param basePoints The base points of the question (e.g. 10).
 * @param responseTimeMs How long the player took to answer in milliseconds.
 * @param maxTimeMs The maximum allowed time for the question (secondsPerQuestion * 1000).
 * @returns { isCorrect, pointsAwarded }
 */
export function computeScore(
  isCorrect: boolean,
  basePoints: number,
  responseTimeMs: number,
  maxTimeMs: number
): { isCorrect: boolean; pointsAwarded: number } {
  if (!isCorrect) {
    return { isCorrect: false, pointsAwarded: 0 };
  }

  // Ensure response time is clamped between 0 and maxTimeMs
  const clampTime = Math.max(0, Math.min(responseTimeMs, maxTimeMs));
  
  // Ratio of time remaining. 
  // If answered instantly (0ms), ratio = 1.0. 
  // If answered at maxTime, ratio = 0.0.
  const speedRatio = (maxTimeMs - clampTime) / maxTimeMs;
  
  // Up to 50% bonus
  const speedBonus = Math.round(basePoints * 0.5 * speedRatio);
  
  const pointsAwarded = basePoints + speedBonus;

  return { isCorrect: true, pointsAwarded };
}
