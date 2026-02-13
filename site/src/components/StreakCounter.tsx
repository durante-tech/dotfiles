import { useState, useEffect } from 'react';
import { getStreakDisplay, getLast30DaysActivity } from '../lib/streak';

export default function StreakCounter() {
  const [streak, setStreak] = useState({ current: 0, longest: 0, isActiveToday: false });
  const [activity, setActivity] = useState<boolean[]>([]);

  useEffect(() => {
    setStreak(getStreakDisplay());
    setActivity(getLast30DaysActivity());
  }, []);

  if (streak.current === 0 && !streak.isActiveToday) {
    return (
      <div className="streak-counter streak-counter--empty">
        <span className="streak-flame">&#x1F525;</span>
        <span className="streak-text">Start your streak!</span>
      </div>
    );
  }

  return (
    <div className="streak-counter">
      <div className="streak-main">
        <span className={`streak-flame ${streak.isActiveToday ? 'streak-flame--active' : ''}`}>
          &#x1F525;
        </span>
        <span className="streak-number">{streak.current}</span>
        <span className="streak-label">day{streak.current !== 1 ? 's' : ''}</span>
      </div>
      {streak.longest > streak.current && (
        <div className="streak-best">Best: {streak.longest}</div>
      )}
      {activity.length > 0 && (
        <div className="streak-dots">
          {activity.slice(-14).map((active, i) => (
            <span
              key={i}
              className={`streak-dot ${active ? 'streak-dot--active' : ''}`}
              title={active ? 'Active' : 'Inactive'}
            />
          ))}
        </div>
      )}
    </div>
  );
}
