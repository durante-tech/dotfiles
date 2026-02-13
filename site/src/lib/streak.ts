/**
 * Streak tracking logic for daily course engagement.
 */

import { getProgress, saveProgress, type StreakData } from './progress';

function getLocalDateString(date?: Date): string {
  const d = date || new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

export function recordActivity(): StreakData {
  const progress = getProgress();
  const today = getLocalDateString();
  const streak = progress.streak;

  if (streak.lastActiveDate === today) return streak;

  const yesterday = getLocalDateString(new Date(Date.now() - 86400000));

  if (streak.lastActiveDate === yesterday) {
    streak.currentStreak += 1;
  } else {
    streak.currentStreak = 1;
  }

  if (streak.currentStreak > streak.longestStreak) {
    streak.longestStreak = streak.currentStreak;
  }

  streak.lastActiveDate = today;

  if (!streak.history.includes(today)) {
    streak.history.push(today);
    if (streak.history.length > 30) {
      streak.history = streak.history.slice(-30);
    }
  }

  saveProgress(progress);
  return streak;
}

export function getStreakDisplay(): { current: number; longest: number; isActiveToday: boolean } {
  const progress = getProgress();
  const today = getLocalDateString();
  return {
    current: progress.streak.currentStreak,
    longest: progress.streak.longestStreak,
    isActiveToday: progress.streak.lastActiveDate === today,
  };
}

export function getLast30DaysActivity(): boolean[] {
  const progress = getProgress();
  const today = new Date();
  const days: boolean[] = [];

  for (let i = 29; i >= 0; i--) {
    const date = new Date(today.getTime() - i * 86400000);
    const dateStr = getLocalDateString(date);
    days.push(progress.streak.history.includes(dateStr));
  }

  return days;
}
