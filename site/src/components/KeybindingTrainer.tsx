import { useState, useEffect, useCallback, useRef } from 'react';
import { getProgress, saveProgress } from '../lib/progress';
import { createCard, reviewCard, binaryToQuality, getDueCards, type SM2Card } from '../lib/spaced-repetition';

interface Drill {
  keys: string;
  action: string;
  context: string;
  category: string;
  difficulty: number;
  mnemonic: string;
}

interface DrillSet {
  id: string;
  title: string;
  description: string;
  drills: Drill[];
}

interface Props {
  drillSet: DrillSet;
  maxQuestions?: number;
}

type Mode = 'learn' | 'drill' | 'test';
type Phase = 'prompt' | 'input' | 'feedback' | 'summary';

export default function KeybindingTrainer({ drillSet, maxQuestions = 10 }: Props) {
  const [mode, setMode] = useState<Mode>('learn');
  const [phase, setPhase] = useState<Phase>('prompt');
  const [currentIndex, setCurrentIndex] = useState(0);
  const [userInput, setUserInput] = useState('');
  const [isCorrect, setIsCorrect] = useState<boolean | null>(null);
  const [startTime, setStartTime] = useState(0);
  const [results, setResults] = useState<{ drill: Drill; correct: boolean; timeMs: number }[]>([]);
  const [shuffledDrills, setShuffledDrills] = useState<Drill[]>([]);
  const inputRef = useRef<HTMLInputElement>(null);

  // Shuffle and select drills based on mode
  useEffect(() => {
    const drills = [...drillSet.drills];

    if (mode === 'drill') {
      // Use SM-2 to prioritize due items
      const progress = getProgress();
      const cards: (SM2Card & { drill: Drill })[] = drills.map((drill) => {
        const cardId = `${drillSet.id}:${drill.keys}`;
        const existing = progress.drills.keybindings[cardId];
        const card = existing
          ? { ...existing, id: cardId } as SM2Card
          : createCard(cardId);
        return { ...card, drill };
      });

      const dueCards = getDueCards(cards);
      const selected = dueCards.length > 0
        ? dueCards.slice(0, maxQuestions).map((c) => (c as any).drill)
        : shuffle(drills).slice(0, maxQuestions);
      setShuffledDrills(selected);
    } else {
      setShuffledDrills(mode === 'test' ? shuffle(drills).slice(0, maxQuestions) : drills);
    }

    setCurrentIndex(0);
    setResults([]);
    setPhase(mode === 'learn' ? 'prompt' : 'prompt');
  }, [mode, drillSet, maxQuestions]);

  const currentDrill = shuffledDrills[currentIndex];

  const handleInputKeyDown = useCallback((e: React.KeyboardEvent<HTMLInputElement>) => {
    e.preventDefault();

    // Build key string from event
    const parts: string[] = [];
    if (e.ctrlKey) parts.push('Ctrl');
    if (e.altKey) parts.push('Alt');
    if (e.shiftKey && e.key.length > 1) parts.push('Shift');
    if (e.metaKey) parts.push('Cmd');

    const key = e.key;
    if (!['Control', 'Alt', 'Shift', 'Meta'].includes(key)) {
      if (key === ' ') parts.push('Space');
      else if (key === 'Escape') parts.push('Escape');
      else if (key === 'Enter') parts.push('Enter');
      else if (key === 'Tab') parts.push('Tab');
      else if (key === 'Backspace') parts.push('Backspace');
      else if (key.length === 1) parts.push(e.shiftKey && key.length === 1 ? key : key);
      else parts.push(key);
    } else {
      return; // Don't process modifier-only presses
    }

    const pressed = parts.join('+');
    setUserInput(pressed);

    // Check answer
    const timeMs = Date.now() - startTime;
    const correct = normalizeKeys(pressed) === normalizeKeys(currentDrill.keys);
    setIsCorrect(correct);
    setPhase('feedback');

    // Record result
    const result = { drill: currentDrill, correct, timeMs };
    setResults((prev) => [...prev, result]);

    // Update SM-2 in drill mode
    if (mode === 'drill' || mode === 'test') {
      const progress = getProgress();
      const cardId = `${drillSet.id}:${currentDrill.keys}`;
      const existing = progress.drills.keybindings[cardId];
      const card = existing ? { ...existing, id: cardId } as SM2Card : createCard(cardId);
      const quality = binaryToQuality(correct, timeMs);
      const updated = reviewCard(card, quality);

      progress.drills.keybindings[cardId] = {
        correct: (existing?.correct || 0) + (correct ? 1 : 0),
        incorrect: (existing?.incorrect || 0) + (correct ? 0 : 1),
        easeFactor: updated.easeFactor,
        interval: updated.interval,
        nextReview: updated.nextReview,
        lastReview: updated.lastReview,
      } as any;

      progress.drills.totalDrills += 1;
      if (correct) progress.drills.totalCorrect += 1;
      else progress.drills.totalIncorrect += 1;

      saveProgress(progress);
    }
  }, [currentDrill, startTime, mode, drillSet.id]);

  const nextQuestion = useCallback(() => {
    if (currentIndex >= shuffledDrills.length - 1) {
      setPhase('summary');
    } else {
      setCurrentIndex((prev) => prev + 1);
      setUserInput('');
      setIsCorrect(null);
      setPhase(mode === 'learn' ? 'prompt' : 'prompt');
      setStartTime(Date.now());
    }
  }, [currentIndex, shuffledDrills.length, mode]);

  const startDrill = useCallback(() => {
    setPhase('input');
    setStartTime(Date.now());
    setTimeout(() => inputRef.current?.focus(), 50);
  }, []);

  if (!currentDrill && phase !== 'summary') {
    return (
      <div className="kb-trainer">
        <div className="kb-trainer-empty">No drills available for this set.</div>
      </div>
    );
  }

  return (
    <div className="kb-trainer">
      {/* Mode Selector */}
      <div className="kb-modes">
        {(['learn', 'drill', 'test'] as Mode[]).map((m) => (
          <button
            key={m}
            className={`kb-mode-btn ${mode === m ? 'kb-mode-btn--active' : ''}`}
            onClick={() => setMode(m)}
          >
            {m === 'learn' ? 'Learn' : m === 'drill' ? 'Drill' : 'Test'}
          </button>
        ))}
        <span className="kb-set-title">{drillSet.title}</span>
      </div>

      {/* Progress indicator */}
      {phase !== 'summary' && (
        <div className="kb-progress-indicator">
          {currentIndex + 1} / {shuffledDrills.length}
        </div>
      )}

      {/* Learn Mode */}
      {mode === 'learn' && phase === 'prompt' && currentDrill && (
        <div className="kb-learn">
          <div className="kb-action">{currentDrill.action}</div>
          <div className="kb-context">{currentDrill.context}</div>
          <div className="kb-answer-display">
            <kbd className="kb-keys-display">{currentDrill.keys}</kbd>
          </div>
          {currentDrill.mnemonic && (
            <div className="kb-mnemonic">Mnemonic: {currentDrill.mnemonic}</div>
          )}
          <button className="kb-next-btn" onClick={nextQuestion}>
            {currentIndex < shuffledDrills.length - 1 ? 'Next' : 'Finish'} &rarr;
          </button>
        </div>
      )}

      {/* Drill/Test Mode - Prompt */}
      {(mode === 'drill' || mode === 'test') && phase === 'prompt' && currentDrill && (
        <div className="kb-prompt">
          <div className="kb-action">{currentDrill.action}</div>
          <div className="kb-context">{currentDrill.context}</div>
          <button className="kb-start-btn" onClick={startDrill}>
            Press the keys &rarr;
          </button>
        </div>
      )}

      {/* Input Phase */}
      {phase === 'input' && currentDrill && (
        <div className="kb-input-phase">
          <div className="kb-action">{currentDrill.action}</div>
          <div className="kb-context">{currentDrill.context}</div>
          <div className="kb-input-area">
            <input
              ref={inputRef}
              className="kb-key-input"
              onKeyDown={handleInputKeyDown}
              value={userInput || 'Press the key combination...'}
              readOnly
              autoFocus
            />
          </div>
        </div>
      )}

      {/* Feedback Phase */}
      {phase === 'feedback' && currentDrill && (
        <div className={`kb-feedback ${isCorrect ? 'kb-feedback--correct' : 'kb-feedback--incorrect'}`}>
          <div className="kb-feedback-icon">{isCorrect ? '\u2714' : '\u2718'}</div>
          <div className="kb-feedback-text">
            {isCorrect ? 'Correct!' : 'Not quite.'}
          </div>
          {!isCorrect && (
            <div className="kb-correct-answer">
              Correct answer: <kbd>{currentDrill.keys}</kbd>
            </div>
          )}
          {!isCorrect && currentDrill.mnemonic && (
            <div className="kb-mnemonic">Remember: {currentDrill.mnemonic}</div>
          )}
          <div className="kb-you-pressed">
            You pressed: <kbd>{userInput}</kbd>
          </div>
          <button className="kb-next-btn" onClick={nextQuestion}>
            {currentIndex < shuffledDrills.length - 1 ? 'Next' : 'See Results'} &rarr;
          </button>
        </div>
      )}

      {/* Summary */}
      {phase === 'summary' && (
        <div className="kb-summary">
          <h3>Results</h3>
          <div className="kb-summary-stats">
            <div className="kb-stat">
              <span className="kb-stat-value">
                {results.filter((r) => r.correct).length}/{results.length}
              </span>
              <span className="kb-stat-label">Correct</span>
            </div>
            <div className="kb-stat">
              <span className="kb-stat-value">
                {results.length > 0
                  ? Math.round((results.filter((r) => r.correct).length / results.length) * 100)
                  : 0}%
              </span>
              <span className="kb-stat-label">Accuracy</span>
            </div>
          </div>
          <div className="kb-summary-list">
            {results.map((r, i) => (
              <div key={i} className={`kb-summary-item ${r.correct ? '' : 'kb-summary-item--wrong'}`}>
                <span className="kb-summary-icon">{r.correct ? '\u2714' : '\u2718'}</span>
                <span className="kb-summary-action">{r.drill.action}</span>
                <kbd className="kb-summary-keys">{r.drill.keys}</kbd>
              </div>
            ))}
          </div>
          <button className="kb-next-btn" onClick={() => { setMode(mode); }}>
            Try Again
          </button>
        </div>
      )}
    </div>
  );
}

function shuffle<T>(array: T[]): T[] {
  const arr = [...array];
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

function normalizeKeys(keys: string): string {
  return keys
    .toLowerCase()
    .replace(/\s+/g, '')
    .replace(/ctrl\+/g, 'ctrl+')
    .replace(/alt\+/g, 'alt+')
    .replace(/shift\+/g, 'shift+')
    .replace(/cmd\+/g, 'cmd+')
    .replace(/space/g, ' ');
}
