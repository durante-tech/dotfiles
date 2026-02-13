import { useState, useEffect } from 'react';

interface Props {
  level: number;
}

const STORAGE_KEY = 'dotfiles-mastery-progress';

export default function LevelGateBanner({ level }: Props) {
  const [unlocked, setUnlocked] = useState(true);
  const [dismissed, setDismissed] = useState(false);

  useEffect(() => {
    if (level === 0) return;
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) {
        setUnlocked(false);
        return;
      }
      const progress = JSON.parse(raw);
      const lessons = progress.lessons || {};
      const completedCount = Object.values(lessons).filter(
        (l: any) => l.completed
      ).length;
      // Soft gate: unlock if any progress exists
      if (completedCount === 0) {
        setUnlocked(false);
      }
    } catch {
      setUnlocked(false);
    }
  }, [level]);

  if (unlocked || dismissed || level === 0) return null;

  return (
    <div className="level-gate-banner">
      <span className="level-gate-banner-icon">&#x1F512;</span>
      <span className="level-gate-banner-text">
        This is Level {level} content. Complete earlier levels first for the best learning experience.
      </span>
      <button
        className="level-gate-banner-dismiss"
        onClick={() => setDismissed(true)}
      >
        Continue anyway
      </button>
    </div>
  );
}
