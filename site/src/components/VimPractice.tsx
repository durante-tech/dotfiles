import { useState, useCallback } from 'react';

interface Exercise {
  id: string;
  title: string;
  description: string;
  initialContent: string;
  targetContent: string;
  hints: string[];
  commands: string[];
}

interface Props {
  exercise: Exercise;
}

/**
 * VimPractice: Interactive vim exercise component.
 *
 * For MVP, this shows exercise instructions with expected commands.
 * When SharedArrayBuffer is available (requires COOP/COEP headers),
 * it can be upgraded to embed vim.wasm for live practice.
 */
export default function VimPractice({ exercise }: Props) {
  const [showAnswer, setShowAnswer] = useState(false);
  const [currentHint, setCurrentHint] = useState(0);

  const nextHint = useCallback(() => {
    setCurrentHint((prev) => Math.min(prev + 1, exercise.hints.length - 1));
  }, [exercise.hints.length]);

  return (
    <div className="vim-practice">
      <div className="vim-practice-header">
        <span className="vim-practice-icon">&#xf120;</span>
        <h4 className="vim-practice-title">{exercise.title}</h4>
      </div>

      <p className="vim-practice-desc">{exercise.description}</p>

      <div className="vim-practice-panels">
        <div className="vim-practice-panel">
          <div className="vim-practice-panel-label">Before:</div>
          <pre className="vim-practice-code">{exercise.initialContent}</pre>
        </div>
        <div className="vim-practice-arrow">&#x2192;</div>
        <div className="vim-practice-panel">
          <div className="vim-practice-panel-label">After:</div>
          <pre className="vim-practice-code">{exercise.targetContent}</pre>
        </div>
      </div>

      <div className="vim-practice-actions">
        {currentHint < exercise.hints.length && (
          <button className="vim-practice-btn vim-practice-btn--hint" onClick={nextHint}>
            {currentHint === 0 ? 'Show Hint' : 'Next Hint'}
          </button>
        )}
        <button
          className="vim-practice-btn vim-practice-btn--answer"
          onClick={() => setShowAnswer(!showAnswer)}
        >
          {showAnswer ? 'Hide Answer' : 'Show Answer'}
        </button>
      </div>

      {currentHint > 0 && (
        <div className="vim-practice-hints">
          {exercise.hints.slice(0, currentHint).map((hint, i) => (
            <div key={i} className="vim-practice-hint">
              <span className="vim-practice-hint-num">Hint {i + 1}:</span> {hint}
            </div>
          ))}
        </div>
      )}

      {showAnswer && (
        <div className="vim-practice-answer">
          <div className="vim-practice-answer-label">Solution:</div>
          <div className="vim-practice-commands">
            {exercise.commands.map((cmd, i) => (
              <div key={i} className="vim-practice-command">
                <kbd>{cmd}</kbd>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
