import { useState, useEffect } from 'react';
import { getAllLevelsInfo, type LevelInfo } from '../lib/level-gates';

const DARK_COLORS = {
  locked: { fill: '#313244', stroke: '#45475a', text: '#6c7086' },
  available: { fill: '#1f1d2e', stroke: '#cba6f7', text: '#cdd6f4' },
  inProgress: { fill: '#1f1d2e', stroke: '#f9e2af', text: '#cdd6f4' },
  completed: { fill: '#1a3a2a', stroke: '#a6e3a1', text: '#a6e3a1' },
  line: { active: '#585b70', inactive: '#313244' },
};

const LIGHT_COLORS = {
  locked: { fill: '#e6e6e6', stroke: '#ccc', text: '#999' },
  available: { fill: '#f8f5ff', stroke: '#7c3aed', text: '#333' },
  inProgress: { fill: '#fffbeb', stroke: '#d97706', text: '#333' },
  completed: { fill: '#ecfdf5', stroke: '#16a34a', text: '#16a34a' },
  line: { active: '#ccc', inactive: '#e6e6e6' },
};

export default function LevelMap() {
  const [levels, setLevels] = useState<LevelInfo[]>([]);
  const [isDark, setIsDark] = useState(true);

  useEffect(() => {
    setLevels(getAllLevelsInfo());

    const checkTheme = () => {
      const theme = document.documentElement.dataset.theme;
      setIsDark(theme !== 'light');
    };
    checkTheme();

    const observer = new MutationObserver(checkTheme);
    observer.observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme'] });
    return () => observer.disconnect();
  }, []);

  if (levels.length === 0) return null;

  const colors = isDark ? DARK_COLORS : LIGHT_COLORS;
  const nodeWidth = 100;
  const nodeHeight = 80;
  const gapX = 30;
  const padding = 20;
  const totalWidth = levels.length * (nodeWidth + gapX) - gapX + padding * 2;
  const totalHeight = nodeHeight + padding * 2 + 30;

  return (
    <div className="level-map-wrapper" role="navigation" aria-label="Course level map">
      <svg
        viewBox={`0 0 ${totalWidth} ${totalHeight}`}
        className="level-map-svg"
        xmlns="http://www.w3.org/2000/svg"
      >
        {/* Connection lines */}
        {levels.slice(0, -1).map((_, i) => {
          const x1 = padding + i * (nodeWidth + gapX) + nodeWidth;
          const x2 = padding + (i + 1) * (nodeWidth + gapX);
          const y = padding + nodeHeight / 2;
          const nextLevel = levels[i + 1];
          const lineColor = nextLevel.unlocked ? colors.line.active : colors.line.inactive;
          return (
            <line
              key={`line-${i}`}
              x1={x1}
              y1={y}
              x2={x2}
              y2={y}
              stroke={lineColor}
              strokeWidth={2}
              strokeDasharray={nextLevel.unlocked ? 'none' : '4 4'}
            />
          );
        })}

        {/* Level nodes */}
        {levels.map((level, i) => {
          const x = padding + i * (nodeWidth + gapX);
          const y = padding;

          let state: 'locked' | 'available' | 'inProgress' | 'completed';
          if (level.percentage === 100) state = 'completed';
          else if (level.completedLessons > 0) state = 'inProgress';
          else if (level.unlocked) state = 'available';
          else state = 'locked';

          const nodeColors = colors[state];
          const progressAngle = (level.percentage / 100) * 360;

          return (
            <g key={level.level} tabIndex={0} role="button" aria-label={`Level ${level.level}: ${level.title} - ${level.percentage}% complete`}>
              <rect
                x={x}
                y={y}
                width={nodeWidth}
                height={nodeHeight}
                rx={10}
                fill={nodeColors.fill}
                stroke={nodeColors.stroke}
                strokeWidth={2}
              />

              {level.percentage > 0 && level.percentage < 100 && (
                <circle
                  cx={x + nodeWidth / 2}
                  cy={y + 28}
                  r={16}
                  fill="none"
                  stroke={nodeColors.stroke}
                  strokeWidth={3}
                  strokeDasharray={`${(progressAngle / 360) * 100.5} 100.5`}
                  strokeLinecap="round"
                  transform={`rotate(-90 ${x + nodeWidth / 2} ${y + 28})`}
                  opacity={0.6}
                />
              )}

              <text x={x + nodeWidth / 2} y={y + 33} textAnchor="middle" fill={nodeColors.text} fontSize="18" fontWeight="700" fontFamily="system-ui, sans-serif">
                {level.level}
              </text>

              <text x={x + nodeWidth / 2} y={y + 55} textAnchor="middle" fill={nodeColors.text} fontSize="9" fontFamily="system-ui, sans-serif" opacity={0.8}>
                {level.title}
              </text>

              <text x={x + nodeWidth / 2} y={y + 70} textAnchor="middle" fill={nodeColors.text} fontSize="8" fontFamily="system-ui, sans-serif" opacity={0.6}>
                {level.completedLessons}/{level.totalLessons}
              </text>

              {state === 'locked' && (
                <text x={x + nodeWidth - 12} y={y + 14} fill={colors.locked.text} fontSize="10" textAnchor="middle">
                  &#x1F512;
                </text>
              )}

              {state === 'completed' && (
                <text x={x + nodeWidth - 12} y={y + 14} fill={colors.completed.stroke} fontSize="12" textAnchor="middle">
                  &#x2714;
                </text>
              )}

              {state === 'inProgress' && (
                <rect x={x} y={y} width={nodeWidth} height={nodeHeight} rx={10} fill="none" stroke={colors.inProgress.stroke} strokeWidth={2} opacity={0.3}>
                  <animate attributeName="opacity" values="0.3;0.1;0.3" dur="2s" repeatCount="indefinite" />
                </rect>
              )}
            </g>
          );
        })}
      </svg>
    </div>
  );
}
