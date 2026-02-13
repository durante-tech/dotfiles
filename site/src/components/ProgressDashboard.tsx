import { useState, useEffect, useCallback } from 'react';
import { getProgress, exportProgress, importProgress, resetProgress, type CourseProgress } from '../lib/progress';
import { getAllLevelsInfo, type LevelInfo } from '../lib/level-gates';
import { getStreakDisplay, getLast30DaysActivity } from '../lib/streak';

export default function ProgressDashboard() {
  const [levels, setLevels] = useState<LevelInfo[]>([]);
  const [streak, setStreak] = useState({ current: 0, longest: 0, isActiveToday: false });
  const [activity, setActivity] = useState<boolean[]>([]);
  const [progress, setProgress] = useState<CourseProgress | null>(null);
  const [showImport, setShowImport] = useState(false);
  const [importText, setImportText] = useState('');

  const refresh = useCallback(() => {
    setLevels(getAllLevelsInfo());
    setStreak(getStreakDisplay());
    setActivity(getLast30DaysActivity());
    setProgress(getProgress());
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const handleExport = useCallback(() => {
    const data = exportProgress();
    const blob = new Blob([data], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `dotfiles-mastery-progress-${new Date().toISOString().slice(0, 10)}.json`;
    a.click();
    URL.revokeObjectURL(url);
  }, []);

  const handleImport = useCallback(() => {
    if (importProgress(importText)) {
      setShowImport(false);
      setImportText('');
      refresh();
    } else {
      alert('Invalid progress data. Please check the JSON format.');
    }
  }, [importText, refresh]);

  const handleReset = useCallback(() => {
    if (confirm('This will erase all your progress. Are you sure?')) {
      resetProgress();
      refresh();
    }
  }, [refresh]);

  const totalLessons = levels.reduce((sum, l) => sum + l.totalLessons, 0);
  const completedLessons = levels.reduce((sum, l) => sum + l.completedLessons, 0);
  const overallPercentage = totalLessons > 0 ? Math.round((completedLessons / totalLessons) * 100) : 0;

  return (
    <div className="progress-dashboard">
      {/* Overview */}
      <div className="pd-overview">
        <div className="pd-stat">
          <div className="pd-stat-value">{overallPercentage}%</div>
          <div className="pd-stat-label">Complete</div>
        </div>
        <div className="pd-stat">
          <div className="pd-stat-value">{completedLessons}/{totalLessons}</div>
          <div className="pd-stat-label">Lessons</div>
        </div>
        <div className="pd-stat">
          <div className={`pd-stat-value ${streak.isActiveToday ? 'pd-stat-value--active' : ''}`}>
            {streak.current}
          </div>
          <div className="pd-stat-label">Day Streak</div>
        </div>
        <div className="pd-stat">
          <div className="pd-stat-value">{streak.longest}</div>
          <div className="pd-stat-label">Best Streak</div>
        </div>
      </div>

      {/* Activity Heatmap */}
      <div className="pd-section">
        <h3>Last 30 Days</h3>
        <div className="pd-heatmap">
          {activity.map((active, i) => (
            <span
              key={i}
              className={`pd-heatmap-cell ${active ? 'pd-heatmap-cell--active' : ''}`}
            />
          ))}
        </div>
      </div>

      {/* Level Progress */}
      <div className="pd-section">
        <h3>Levels</h3>
        {levels.map((level) => (
          <div key={level.level} className={`pd-level ${!level.unlocked ? 'pd-level--locked' : ''}`}>
            <div className="pd-level-header">
              <span className="pd-level-name">
                Level {level.level}: {level.title}
                {!level.unlocked && <span className="pd-level-lock"> &#x1F512;</span>}
              </span>
              <span className="pd-level-count">
                {level.completedLessons}/{level.totalLessons}
              </span>
            </div>
            <div className="pd-progress-bar">
              <div
                className="pd-progress-fill"
                style={{ width: `${level.percentage}%` }}
              />
            </div>
            <div className="pd-level-subtitle">{level.subtitle}</div>
          </div>
        ))}
      </div>

      {/* Drill Stats */}
      {progress && progress.drills.totalDrills > 0 && (
        <div className="pd-section">
          <h3>Keybinding Drills</h3>
          <div className="pd-overview">
            <div className="pd-stat">
              <div className="pd-stat-value">{progress.drills.totalDrills}</div>
              <div className="pd-stat-label">Total Drills</div>
            </div>
            <div className="pd-stat">
              <div className="pd-stat-value">
                {progress.drills.totalDrills > 0
                  ? Math.round((progress.drills.totalCorrect / progress.drills.totalDrills) * 100)
                  : 0}%
              </div>
              <div className="pd-stat-label">Accuracy</div>
            </div>
          </div>
        </div>
      )}

      {/* Data Management */}
      <div className="pd-section pd-actions">
        <h3>Data</h3>
        <div className="pd-btn-group">
          <button className="pd-btn" onClick={handleExport}>Export Progress</button>
          <button className="pd-btn" onClick={() => setShowImport(!showImport)}>Import Progress</button>
          <button className="pd-btn pd-btn--danger" onClick={handleReset}>Reset All</button>
        </div>
        {showImport && (
          <div className="pd-import">
            <textarea
              className="pd-import-textarea"
              value={importText}
              onChange={(e) => setImportText(e.target.value)}
              placeholder="Paste exported JSON here..."
              rows={6}
            />
            <button className="pd-btn" onClick={handleImport}>Import</button>
          </div>
        )}
      </div>
    </div>
  );
}
