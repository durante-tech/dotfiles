import { beforeEach, test, expect } from 'bun:test';
import { getProgress, saveProgress, importProgress, exportProgress, migrateProgress, getStorageNotice, STORAGE_KEY, V1_BACKUP_KEY } from '../src/lib/progress';
import { createCard, reviewCard } from '../src/lib/spaced-repetition';
import { eventKey, parseNotation, sequenceState } from '../src/lib/key-sequence';

const storage = new Map<string, string>();
beforeEach(() => {
  storage.clear();
  Object.assign(globalThis, {window: {}, localStorage: {getItem: (k: string) => storage.get(k) ?? null, setItem: (k: string, v: string) => storage.set(k, v), removeItem: (k: string) => storage.delete(k)}});
  getProgress();
});

test('v1 migration backs up raw data, retains history, reschedules unknown repetitions once', () => {
  const v1: any = getProgress(); v1.version = 1;
  v1.lessons.a = {lessonId:'a', slug:'tmux', completed:true, completedAt:'2026-01-01T00:00:00Z'};
  v1.streak = {currentStreak:2,longestStreak:5,lastActiveDate:'2026-01-01',history:['2026-01-01']};
  v1.drills = {totalDrills:10,totalCorrect:8,totalIncorrect:2,keybindings:{'tmux-core:Ctrl+Space |':{correct:8,incorrect:2,easeFactor:2.5,interval:90,nextReview:'2027-01-01T00:00:00Z',lastReview:'2026-01-01T00:00:00Z'}}};
  const raw = JSON.stringify(v1); storage.set(STORAGE_KEY,raw);
  const v2 = getProgress(); const stat = v2.drills.keybindings['tmux-core:Ctrl+Space |'];
  expect(storage.get(V1_BACKUP_KEY)).toBe(raw);
  expect(v2.version).toBe(2); expect(v2.lessons).toEqual(v1.lessons); expect(v2.streak).toEqual(v1.streak);
  expect(stat).toMatchObject({correct:8,incorrect:2,repetitions:0,interval:0});
  expect(Date.parse(stat.nextReview)).toBeLessThanOrEqual(Date.now());
  expect(v2.drills.keybindings['tmux-core:Ctrl+b |']).toBeUndefined();
  expect(getProgress()).toEqual(v2); expect(migrateProgress(v2)).toEqual(v2);
});

test('persisted repetitions advance through one day then six days and reset after failure', () => {
  let card = reviewCard(createCard('test'), 5); const progress = getProgress();
  progress.drills = {totalDrills:1,totalCorrect:1,totalIncorrect:0,keybindings:{test:{...card,correct:1,incorrect:0}}};
  expect(saveProgress(progress)).toBe(true);
  card = reviewCard({...getProgress().drills.keybindings.test,id:'test'},5);
  expect(card.repetitions).toBe(2); expect(card.interval).toBe(6);
  expect(reviewCard(card,1)).toMatchObject({repetitions:0,interval:1});
});

test('malformed and future imports cannot overwrite progress', () => {
  const progress=getProgress(); saveProgress(progress);const before=storage.get(STORAGE_KEY);
  for (const invalid of ['{}','{',JSON.stringify({...progress,version:99}),JSON.stringify({...progress,drills:{totalDrills:-1}})]) {
    expect(importProgress(invalid)).toBe(false);expect(storage.get(STORAGE_KEY)).toBe(before);
  }
});

test('unreadable saved data stays exportable and blocks automatic saves', () => {
  const raw='{"version":99,"important":"keep"}'; storage.set(STORAGE_KEY,raw);
  const fallback=getProgress();expect(getStorageNotice()).toContain('preserved');
  expect(saveProgress(fallback)).toBe(false);expect(exportProgress()).toBe(raw);
  expect(storage.get(STORAGE_KEY)).toBe(raw);
});

test('valid v1 import preserves original and current backups', () => {
  const previous=JSON.stringify(getProgress());storage.set(STORAGE_KEY,previous);
  const data={...getProgress(),version:1};expect(importProgress(JSON.stringify(data))).toBe(true);
  expect(storage.get(STORAGE_KEY+'-backup-before-import')).toBe(previous);
  expect(storage.get(V1_BACKUP_KEY)).toBe(JSON.stringify(data));expect(getProgress().version).toBe(2);
});

test('ordered sequences preserve case, chords, and valid prefixes', () => {
  expect(parseNotation('gg')).toEqual(['g','g']);expect(parseNotation('Ctrl+b |')).toEqual(['Ctrl+b','|']);
  expect(parseNotation('Space p f')).toEqual(['Space','p','f']);
  expect(sequenceState(['g','g'],['g'])).toBe('prefix');
  expect(sequenceState(['G'],['g'])).toBe('incorrect');
  expect(sequenceState(['Ctrl+b','|'],['Ctrl+b','|'])).toBe('correct');
  const event={key:'H',code:'KeyH',ctrlKey:false,altKey:true,shiftKey:true,metaKey:false,repeat:false,isComposing:false};
  expect(eventKey(event)).toBe('Alt+Shift+h');
  expect(eventKey({...event,repeat:true})).toBeNull();
  expect(eventKey({...event,altKey:false})).toBe('H');
  expect(eventKey({...event,key:'Dead'})).toBeNull();
});
