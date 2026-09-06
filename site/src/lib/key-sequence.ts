/** Ordered key presses: printable keys retain case; modifiers describe chords. */
export function parseNotation(text: string): string[] {
  const named = new Set(['Space', 'Escape', 'Enter', 'Tab', 'Backspace', 'Delete', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight']);
  return text.trim().split(/\s+/).filter(Boolean).flatMap(part => {
    if (named.has(part) || /^(Ctrl|Alt|Shift|Cmd)\+/.test(part)) return [part];
    return [...part];
  });
}

export function sequenceState(expected: string[], input: string[]): 'prefix' | 'correct' | 'incorrect' {
  if (input.length > expected.length || input.some((key, i) => key !== expected[i])) return 'incorrect';
  return input.length === expected.length ? 'correct' : 'prefix';
}

export function eventKey(e: Pick<KeyboardEvent, 'key' | 'code' | 'ctrlKey' | 'altKey' | 'shiftKey' | 'metaKey' | 'repeat' | 'isComposing'>): string | null {
  if (e.repeat || e.isComposing || ['Control', 'Alt', 'Shift', 'Meta', 'Dead', 'Unidentified'].includes(e.key)) return null;
  const parts: string[] = [];
  if (e.ctrlKey) parts.push('Ctrl');
  if (e.altKey) parts.push('Alt');
  if (e.shiftKey && (e.ctrlKey || e.altKey || e.metaKey || e.key.length !== 1 || e.key === ' ')) parts.push('Shift');
  if (e.metaKey) parts.push('Cmd');
  let key = e.key === ' ' ? 'Space' : e.key;
  if ((e.ctrlKey || e.altKey || e.metaKey) && /^Key[A-Z]$/.test(e.code)) key = e.code.slice(3).toLowerCase();
  parts.push(key);
  return parts.join('+');
}
