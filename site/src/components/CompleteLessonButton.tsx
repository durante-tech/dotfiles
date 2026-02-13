import { useState, useEffect, useCallback } from 'react';
import { markLessonComplete, markLessonIncomplete, isLessonComplete } from '../lib/progress';

interface Props {
  lessonId: string;
  slug: string;
  nextLessonSlug?: string;
  nextLessonTitle?: string;
}

export default function CompleteLessonButton({ lessonId, slug, nextLessonSlug, nextLessonTitle }: Props) {
  const [completed, setCompleted] = useState(false);
  const [animating, setAnimating] = useState(false);

  useEffect(() => {
    setCompleted(isLessonComplete(lessonId));
  }, [lessonId]);

  const toggleComplete = useCallback(() => {
    if (completed) {
      markLessonIncomplete(lessonId);
      setCompleted(false);
    } else {
      markLessonComplete(lessonId, slug);
      setCompleted(true);
      setAnimating(true);
      setTimeout(() => setAnimating(false), 600);
    }
  }, [completed, lessonId, slug]);

  return (
    <div className="complete-lesson">
      <button
        className={`complete-lesson-btn ${completed ? 'complete-lesson-btn--done' : ''} ${animating ? 'complete-lesson-btn--animate' : ''}`}
        onClick={toggleComplete}
      >
        <span className="complete-lesson-check">{completed ? '\u2714' : '\u25CB'}</span>
        <span>{completed ? 'Completed' : 'Mark as Complete'}</span>
      </button>

      {completed && nextLessonSlug && (
        <a className="complete-lesson-next" href={`/${nextLessonSlug}/`}>
          Next: {nextLessonTitle} &rarr;
        </a>
      )}
    </div>
  );
}
