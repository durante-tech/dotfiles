/**
 * localStorage-based progress tracking for the Dotfiles Mastery Course.
 * Schema-versioned for safe upgrades.
 */

export const STORAGE_KEY = 'dotfiles-mastery-progress';
const SCHEMA_VERSION = 2;
export const V1_BACKUP_KEY = STORAGE_KEY + '-backup-v1';
let storageNotice = '';
export function getStorageNotice(): string { return storageNotice; }

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
  repetitions: number;
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

const record = (v: unknown): v is Record<string, any> => !!v && typeof v === 'object' && !Array.isArray(v);
const count = (v: unknown) => Number.isSafeInteger(v) && (v as number) >= 0;
const date = (v: unknown) => typeof v === 'string' && /^\d{4}-\d{2}-\d{2}T/.test(v) && Number.isFinite(Date.parse(v));
const day = (v: unknown) => typeof v === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(v) && Number.isFinite(Date.parse(v));
const nullableDate = (v: unknown) => v === null || date(v);
const dictionary = (v: unknown, check: (value: any) => boolean) => record(v) && Object.entries(v).every(([k, item]) =>
  !['__proto__', 'constructor', 'prototype'].includes(k) && check(item));

/** Validate before reading or replacing saved data, including supported v1 imports. */
export function validateProgress(v: unknown): v is CourseProgress {
  if (!record(v) || ![1, 2].includes(v.version) || !date(v.lastActivity)) return false;
  if (!dictionary(v.lessons, x => record(x) && typeof x.lessonId === 'string' && typeof x.slug === 'string' && typeof x.completed === 'boolean' && nullableDate(x.completedAt))) return false;
  if (!dictionary(v.levels, x => record(x) && count(x.level) && count(x.totalLessons) && count(x.completedLessons) && x.completedLessons <= x.totalLessons && typeof x.unlocked === 'boolean')) return false;
  const s = v.streak, d = v.drills;
  if (!record(s) || !count(s.currentStreak) || !count(s.longestStreak) || !(s.lastActiveDate === null || day(s.lastActiveDate)) || !Array.isArray(s.history) || !s.history.every(day)) return false;
  if (!record(d) || !count(d.totalDrills) || !count(d.totalCorrect) || !count(d.totalIncorrect) || d.totalCorrect + d.totalIncorrect !== d.totalDrills) return false;
  return dictionary(d.keybindings, x => record(x) && count(x.correct) && count(x.incorrect) &&
    Number.isFinite(x.easeFactor) && x.easeFactor >= 1.3 && count(x.interval) && date(x.nextReview) && nullableDate(x.lastReview) &&
    (v.version === 1 || count(x.repetitions)));
}

export function migrateProgress(data: CourseProgress, now = new Date().toISOString()): CourseProgress {
  if (!validateProgress(data)) throw new Error('Malformed or unsupported progress');
  const result = structuredClone(data);
  if (result.version === 1) {
    result.version = 2;
    for (const stat of Object.values(result.drills.keybindings)) {
      // Historical correct counts cannot establish consecutive repetitions.
      stat.repetitions = 0;
      stat.interval = 0;
      stat.nextReview = now;
    }
  }
  return result;
}

export function getProgress(): CourseProgress {
  if (typeof window === 'undefined') return createDefaultProgress();
  storageNotice = '';
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return createDefaultProgress();
    const data: unknown = JSON.parse(raw);
    if (!validateProgress(data)) throw new Error('Malformed or unsupported progress');
    const migrated = migrateProgress(data);
    if (data.version === 1) {
      // Write the original backup first. A quota failure must leave v1 intact.
      if (!localStorage.getItem(V1_BACKUP_KEY)) localStorage.setItem(V1_BACKUP_KEY, raw);
      localStorage.setItem(STORAGE_KEY, JSON.stringify(migrated));
    }
    return migrated;
  } catch {
    storageNotice = 'Saved progress could not be loaded. It is preserved, and automatic saving is paused. Export it before importing a valid backup or resetting.';
    return createDefaultProgress();
  }
}

export function saveProgress(progress: CourseProgress): boolean {
  if (typeof window === 'undefined') return false;
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw && !validateProgress(JSON.parse(raw))) return false;
    if (progress.version !== SCHEMA_VERSION || !validateProgress(progress)) return false;
    // A previous failed migration must never be overwritten by a default view.
    if (storageNotice) return false;
    progress.lastActivity = new Date().toISOString();
    localStorage.setItem(STORAGE_KEY, JSON.stringify(progress));
    return true;
  } catch (error) {
    console.error('Failed to save progress:', error);
    return false;
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
  getProgress();
  if (typeof window !== 'undefined') {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) return raw; // Also permits recovery of malformed or future data.
  }
  return JSON.stringify(createDefaultProgress(), null, 2);
}

export function importProgress(json: string): boolean {
  if (typeof window === 'undefined') return false;
  try {
    const data: unknown = JSON.parse(json);
    if (!validateProgress(data)) return false;
    const migrated = migrateProgress(data);
    const previous = localStorage.getItem(STORAGE_KEY);
    if (previous) localStorage.setItem(STORAGE_KEY + '-backup-before-import', previous);
    if (data.version === 1) {
      localStorage.setItem(STORAGE_KEY + '-backup-v1-import', json);
      if (!localStorage.getItem(V1_BACKUP_KEY)) localStorage.setItem(V1_BACKUP_KEY, json);
    }
    localStorage.setItem(STORAGE_KEY, JSON.stringify(migrated));
    storageNotice = '';
    return true;
  } catch {
    return false;
  }
}

export function resetProgress(): void {
  if (typeof window === 'undefined') return;
  localStorage.removeItem(STORAGE_KEY);
  storageNotice = '';
}
