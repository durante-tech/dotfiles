import { useState, useEffect, useCallback, useRef } from 'react';
import { getProgress, saveProgress } from '../lib/progress';
import { eventKey, parseNotation, sequenceState } from '../lib/key-sequence';
import { createCard, reviewCard, binaryToQuality, getDueCards, type SM2Card } from '../lib/spaced-repetition';

interface Drill {
  keys: string;
  sequence: string[];
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
  const [attempt, setAttempt] = useState(0);
  const [typedMode, setTypedMode] = useState(false);
  const [typedInput, setTypedInput] = useState('');
  const entered = useRef<string[]>([]);
  const finished = useRef(false);
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
          ? { ...existing, id: cardId }
          : createCard(cardId);
        return { ...card, drill };
      });

      const dueCards = getDueCards(cards);
      const selected = dueCards.length > 0
        ? dueCards.slice(0, maxQuestions).map((c) => c.drill)
        : shuffle(drills).slice(0, maxQuestions);
      setShuffledDrills(selected);
    } else {
      setShuffledDrills(mode === 'test' ? shuffle(drills).slice(0, maxQuestions) : drills);
    }

    setCurrentIndex(0);
    setResults([]);
    setUserInput('');
    setTypedInput('');
    setIsCorrect(null);
    entered.current = [];
    finished.current = false;
    setPhase('prompt');
  }, [mode, drillSet, maxQuestions, attempt]);

  const currentDrill = shuffledDrills[currentIndex];

  const submitSequence = useCallback((input: string[], final = false) => {
    if (phase !== 'input' || finished.current) return;
    entered.current = input;
    const pressed = input.join(' ');
    setUserInput(pressed);
    const state = sequenceState(currentDrill.sequence, input);
    if (state === 'prefix' && !final) return;
    finished.current = true;
    // Check answer
    const timeMs = Date.now() - startTime;
    const correct = state === 'correct';
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
      const card = existing ? { ...existing, id: cardId } : createCard(cardId);
      const quality = binaryToQuality(correct, timeMs);
      const updated = reviewCard(card, quality);

      progress.drills.keybindings[cardId] = {
        correct: (existing?.correct || 0) + (correct ? 1 : 0),
        incorrect: (existing?.incorrect || 0) + (correct ? 0 : 1),
        easeFactor: updated.easeFactor,
        interval: updated.interval,
        repetitions: updated.repetitions,
        nextReview: updated.nextReview,
        lastReview: updated.lastReview,
      };

      progress.drills.totalDrills += 1;
      if (correct) progress.drills.totalCorrect += 1;
      else progress.drills.totalIncorrect += 1;

      saveProgress(progress);
    }
  }, [currentDrill, startTime, mode, drillSet.id, phase]);

  const handleInputKeyDown = useCallback((e: React.KeyboardEvent<HTMLInputElement>) => {
    e.preventDefault();
    const key = eventKey(e.nativeEvent);
    if (key) submitSequence([...entered.current, key]);
  }, [submitSequence]);

  const nextQuestion = useCallback(() => {
    if (currentIndex >= shuffledDrills.length - 1) {
      setPhase('summary');
    } else {
      setCurrentIndex((prev) => prev + 1);
      setUserInput('');
      setTypedInput('');
      entered.current = [];
      finished.current = false;
      setIsCorrect(null);
      setPhase(mode === 'learn' ? 'prompt' : 'prompt');
      setStartTime(Date.now());
    }
  }, [currentIndex, shuffledDrills.length, mode]);

  const startDrill = useCallback(() => {
    finished.current = false;
    entered.current = [];
    setUserInput('');
    setTypedInput('');
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
          <label><input type="checkbox" checked={typedMode} onChange={(e) => {
            setTypedMode(e.target.checked); entered.current = []; setUserInput(''); setTypedInput('');
          }} /> Type notation (for shortcuts captured by your browser or OS)</label>
          {typedMode && <p>Use case-sensitive keys, such as <code>Ctrl+b |</code>, <code>gg</code>, or <code>Space p f</code>.</p>}
          <div className="kb-input-area">
            <input
              ref={inputRef}
              className="kb-key-input"
              aria-label={typedMode ? 'Shortcut notation' : 'Shortcut keys'}
              onKeyDown={typedMode ? (e) => { if (e.key === 'Enter' && !e.repeat) { e.preventDefault(); submitSequence(parseNotation(typedInput), true); } } : handleInputKeyDown}
              onChange={typedMode ? (e) => setTypedInput(e.target.value) : undefined}
              value={typedMode ? typedInput : userInput}
              placeholder={typedMode ? 'Type the shortcut notation' : 'Press each key in order...'}
              readOnly={!typedMode}
              autoFocus
            />
          </div>
          {typedMode && <button onClick={() => submitSequence(parseNotation(typedInput), true)}>Check answer</button>}
          {!typedMode && userInput && <p>Sequence so far: <kbd>{userInput}</kbd> — waiting for the next key.</p>}
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
          <button className="kb-next-btn" onClick={() => setAttempt((value) => value + 1)}>
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
