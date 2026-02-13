/**
 * Level gate logic: determines if a level is unlocked based on previous level completion.
 */

import { getProgress } from './progress';
import levelsData from '../data/levels.json';

export interface LevelInfo {
  level: number;
  title: string;
  subtitle: string;
  unlocked: boolean;
  completedLessons: number;
  totalLessons: number;
  gateRequirement: number;
  percentage: number;
}

export function isLevelUnlocked(level: number): boolean {
  if (level === 0) return true;

  const progress = getProgress();
  const previousLevel = levelsData.levels.find((l) => l.level === level - 1);
  if (!previousLevel) return true;

  const completedCount = previousLevel.lessons.filter(
    (lesson) => progress.lessons[lesson.id]?.completed
  ).length;

  return completedCount >= previousLevel.gateRequirement;
}

export function getLevelInfo(level: number): LevelInfo | null {
  const levelData = levelsData.levels.find((l) => l.level === level);
  if (!levelData) return null;

  const progress = getProgress();
  const completedCount = levelData.lessons.filter(
    (lesson) => progress.lessons[lesson.id]?.completed
  ).length;

  return {
    level: levelData.level,
    title: levelData.title,
    subtitle: levelData.subtitle,
    unlocked: isLevelUnlocked(level),
    completedLessons: completedCount,
    totalLessons: levelData.lessons.length,
    gateRequirement: levelData.gateRequirement,
    percentage: levelData.lessons.length > 0
      ? Math.round((completedCount / levelData.lessons.length) * 100)
      : 0,
  };
}

export function getAllLevelsInfo(): LevelInfo[] {
  return levelsData.levels.map((l) => getLevelInfo(l.level)!).filter(Boolean);
}

export function getNextLesson(currentSlug: string): { slug: string; title: string; lessonId: string } | null {
  const allLessons = levelsData.levels.flatMap((l) => l.lessons);
  const currentIndex = allLessons.findIndex((l) => l.slug === currentSlug);

  if (currentIndex === -1 || currentIndex >= allLessons.length - 1) return null;

  const next = allLessons[currentIndex + 1];
  return { slug: next.slug, title: next.title, lessonId: next.id };
}

export function getPreviousLesson(currentSlug: string): { slug: string; title: string; lessonId: string } | null {
  const allLessons = levelsData.levels.flatMap((l) => l.lessons);
  const currentIndex = allLessons.findIndex((l) => l.slug === currentSlug);

  if (currentIndex <= 0) return null;

  const prev = allLessons[currentIndex - 1];
  return { slug: prev.slug, title: prev.title, lessonId: prev.id };
}

export function getLessonLevel(slug: string): number | null {
  for (const level of levelsData.levels) {
    if (level.lessons.some((l) => l.slug === slug)) {
      return level.level;
    }
  }
  return null;
}

export function getLessonId(slug: string): string | null {
  for (const level of levelsData.levels) {
    const lesson = level.lessons.find((l) => l.slug === slug);
    if (lesson) return lesson.id;
  }
  return null;
}
