/**
 * SM-2 Spaced Repetition Algorithm implementation.
 *
 * Based on the SuperMemo SM-2 algorithm by P.A. Wozniak.
 *
 * Quality scale: 0-5
 *   0 - Complete blackout
 *   1 - Wrong, but remembered after seeing answer
 *   2 - Wrong, but close
 *   3 - Correct, but difficult recall
 *   4 - Correct, with slight hesitation
 *   5 - Perfect recall
 */

export interface SM2Card {
  id: string;
  easeFactor: number;   // >= 1.3, starts at 2.5
  interval: number;     // days until next review
  repetitions: number;  // consecutive correct answers
  nextReview: string;   // ISO date string
  lastReview: string | null;
}

export interface ReviewResult {
  card: SM2Card;
  quality: number;      // 0-5
  wasCorrect: boolean;
}

export function createCard(id: string): SM2Card {
  return {
    id,
    easeFactor: 2.5,
    interval: 0,
    repetitions: 0,
    nextReview: new Date().toISOString(),
    lastReview: null,
  };
}

export function reviewCard(card: SM2Card, quality: number): SM2Card {
  // Clamp quality to 0-5
  quality = Math.max(0, Math.min(5, quality));

  const updated = { ...card };

  if (quality >= 3) {
    // Correct response
    if (updated.repetitions === 0) {
      updated.interval = 1;
    } else if (updated.repetitions === 1) {
      updated.interval = 6;
    } else {
      updated.interval = Math.round(updated.interval * updated.easeFactor);
    }
    updated.repetitions += 1;
  } else {
    // Incorrect response - reset
    updated.repetitions = 0;
    updated.interval = 1;
  }

  // Update ease factor
  updated.easeFactor = updated.easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));

  // Minimum ease factor
  if (updated.easeFactor < 1.3) {
    updated.easeFactor = 1.3;
  }

  // Schedule next review
  const nextDate = new Date();
  nextDate.setDate(nextDate.getDate() + updated.interval);
  updated.nextReview = nextDate.toISOString();
  updated.lastReview = new Date().toISOString();

  return updated;
}

export function isDue(card: SM2Card): boolean {
  return new Date(card.nextReview) <= new Date();
}

export function getDueCards(cards: SM2Card[]): SM2Card[] {
  return cards
    .filter(isDue)
    .sort((a, b) => a.easeFactor - b.easeFactor); // Hardest first
}

/**
 * Convert a binary correct/incorrect into a quality score.
 * For keybinding drills where we want simple right/wrong:
 */
export function binaryToQuality(correct: boolean, timeMs: number): number {
  if (!correct) return 1; // Wrong but saw answer

  // Fast correct: quality 5, slow correct: quality 3
  if (timeMs < 2000) return 5;
  if (timeMs < 4000) return 4;
  return 3;
}
