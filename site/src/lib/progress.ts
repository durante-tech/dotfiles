/**
 * localStorage-based progress tracking for the Dotfiles Mastery Course.
 * Schema-versioned for safe upgrades.
 */

const STORAGE_KEY = 'dotfiles-mastery-progress';
const SCHEMA_VERSION = 1;

export interface LessonProgress {
  lessonId: string;
  slug: string;
  completed: boolean;
  completedAt: string | null;
}

export interface LevelProgress {
  level: number;
  totalLessons: number;
  completedLessons: number;
  unlocked: boolean;
}

export interface StreakData {
  currentStreak: number;
  longestStreak: number;
  lastActiveDate: string | null;
  history: string[]; // last 30 YYYY-MM-DD entries
}

export interface KeybindingStat {
  correct: number;
  incorrect: number;
  easeFactor: number;
  interval: number;
  nextReview: string;
  lastReview: string | null;
}

export interface DrillProgress {
  totalDrills: number;
  totalCorrect: number;
  totalIncorrect: number;
  keybindings: Record<string, KeybindingStat>;
}

export interface CourseProgress {
  version: number;
  lessons: Record<string, LessonProgress>;
  levels: Record<string, LevelProgress>;
  streak: StreakData;
  drills: DrillProgress;
  lastActivity: string;
}

function createDefaultProgress(): CourseProgress {
  return {
    version: SCHEMA_VERSION,
    lessons: {},
    levels: {},
    streak: {
      currentStreak: 0,
      longestStreak: 0,
      lastActiveDate: null,
      history: [],
    },
    drills: {
      totalDrills: 0,
      totalCorrect: 0,
      totalIncorrect: 0,
      keybindings: {},
    },
    lastActivity: new Date().toISOString(),
  };
}

export function getProgress(): CourseProgress {
  if (typeof window === 'undefined') return createDefaultProgress();

  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return createDefaultProgress();

    const data = JSON.parse(raw) as CourseProgress;
    if (data.version !== SCHEMA_VERSION) {
      // Future: run migration logic here
      return createDefaultProgress();
    }
    return data;
  } catch {
    return createDefaultProgress();
  }
}

export function saveProgress(progress: CourseProgress): void {
  if (typeof window === 'undefined') return;

  progress.lastActivity = new Date().toISOString();
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(progress));
  } catch (e) {
    console.error('Failed to save progress:', e);
  }
}

export function markLessonComplete(lessonId: string, slug: string): CourseProgress {
  const progress = getProgress();

  progress.lessons[lessonId] = {
    lessonId,
    slug,
    completed: true,
    completedAt: new Date().toISOString(),
  };

  // Update streak
  updateStreak(progress);

  saveProgress(progress);
  return progress;
}

export function markLessonIncomplete(lessonId: string): CourseProgress {
  const progress = getProgress();

  if (progress.lessons[lessonId]) {
    progress.lessons[lessonId].completed = false;
    progress.lessons[lessonId].completedAt = null;
  }

  saveProgress(progress);
  return progress;
}

export function isLessonComplete(lessonId: string): boolean {
  const progress = getProgress();
  return progress.lessons[lessonId]?.completed === true;
}

export function getLevelProgress(level: number, totalLessons: number, lessonIds: string[]): { completed: number; total: number; percentage: number } {
  const progress = getProgress();
  const completed = lessonIds.filter((id) => progress.lessons[id]?.completed).length;
  return {
    completed,
    total: totalLessons,
    percentage: totalLessons > 0 ? Math.round((completed / totalLessons) * 100) : 0,
  };
}

function updateStreak(progress: CourseProgress): void {
  const today = getLocalDateString();
  const streak = progress.streak;

  if (streak.lastActiveDate === today) return; // Already active today

  const yesterday = getLocalDateString(new Date(Date.now() - 86400000));

  if (streak.lastActiveDate === yesterday) {
    streak.currentStreak += 1;
  } else if (streak.lastActiveDate !== today) {
    streak.currentStreak = 1;
  }

  if (streak.currentStreak > streak.longestStreak) {
    streak.longestStreak = streak.currentStreak;
  }

  streak.lastActiveDate = today;

  // Maintain last 30 days history
  if (!streak.history.includes(today)) {
    streak.history.push(today);
    if (streak.history.length > 30) {
      streak.history = streak.history.slice(-30);
    }
  }
}

function getLocalDateString(date?: Date): string {
  const d = date || new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

export function getStreak(): StreakData {
  const progress = getProgress();
  return progress.streak;
}

export function exportProgress(): string {
  return JSON.stringify(getProgress(), null, 2);
}

export function importProgress(json: string): boolean {
  try {
    const data = JSON.parse(json) as CourseProgress;
    if (data.version !== SCHEMA_VERSION) return false;
    saveProgress(data);
    return true;
  } catch {
    return false;
  }
}

export function resetProgress(): void {
  if (typeof window === 'undefined') return;
  localStorage.removeItem(STORAGE_KEY);
}
