import { describe, it, expect } from 'vitest';
import { computeScore } from '../src/scoring.js';

describe('Scoring Logic', () => {
  const BASE_POINTS = 10;
  const MAX_TIME_MS = 15000;

  it('Wrong answer gives 0 points', () => {
    const res = computeScore(false, BASE_POINTS, 5000, MAX_TIME_MS);
    expect(res.isCorrect).toBe(false);
    expect(res.pointsAwarded).toBe(0);
  });

  it('Skipped answer (wrong) gives 0 points', () => {
    // Skipped is usually evaluated as isCorrect: false
    const res = computeScore(false, BASE_POINTS, MAX_TIME_MS, MAX_TIME_MS);
    expect(res.isCorrect).toBe(false);
    expect(res.pointsAwarded).toBe(0);
  });

  it('Correct + Slow gives base points', () => {
    // Answered exactly at max time (0% speed bonus)
    const res = computeScore(true, BASE_POINTS, MAX_TIME_MS, MAX_TIME_MS);
    expect(res.isCorrect).toBe(true);
    expect(res.pointsAwarded).toBe(BASE_POINTS); // 10
  });

  it('Correct + Fast gives up to 50% bonus', () => {
    // Answered instantly (100% speed bonus = 5 points)
    const instant = computeScore(true, BASE_POINTS, 0, MAX_TIME_MS);
    expect(instant.isCorrect).toBe(true);
    expect(instant.pointsAwarded).toBe(15);

    // Answered at 5 seconds out of 15 (66% speed bonus = 3.33 -> 3 points)
    const mid = computeScore(true, BASE_POINTS, 5000, MAX_TIME_MS);
    expect(mid.pointsAwarded).toBe(13);
  });

  it('Clamps negative response times to 0', () => {
    const res = computeScore(true, BASE_POINTS, -1000, MAX_TIME_MS);
    expect(res.pointsAwarded).toBe(15);
  });

  it('Clamps excessively long response times to maxTime', () => {
    const res = computeScore(true, BASE_POINTS, 20000, MAX_TIME_MS);
    expect(res.pointsAwarded).toBe(10); // 0 bonus
  });
});
