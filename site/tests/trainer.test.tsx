import { test, expect, afterEach } from 'bun:test';
import { Window, type HTMLInputElement as HappyInput } from 'happy-dom';
import { act } from 'react';
import type { Root } from 'react-dom/client';
import Trainer from '../src/components/KeybindingTrainer';
import VimPractice from '../src/components/VimPractice';

let root: Root, win: Window;
async function mount(component: React.ReactNode) {
  win = new Window({url:'http://localhost'});
  Object.assign(globalThis,{window:win,document:win.document,navigator:win.navigator,HTMLElement:win.HTMLElement,localStorage:win.localStorage,IS_REACT_ACT_ENVIRONMENT:true});
  const container=win.document.createElement('div');win.document.body.append(container);
  const {createRoot}=await import('react-dom/client');
  root=createRoot(container as unknown as HTMLElement);
  await act(async()=>root.render(component));
}
afterEach(async()=>{if(root) await act(async()=>root.unmount());if(win) await win.happyDOM.close();});
async function click(text: string) {
  const button=[...win.document.querySelectorAll('button')].find(b=>b.textContent?.trim().startsWith(text));
  expect(button).toBeDefined();await act(async()=>button!.click());
}
async function key(value: string, extra={}) {
  const input=win.document.querySelector('.kb-key-input')!;
  await act(async()=>input.dispatchEvent(new win.KeyboardEvent('keydown',{key:value,code:'Key'+value.toUpperCase(),bubbles:true,...extra})));
}
const set={id:'fixture',title:'Fixture',description:'',drills:[{keys:'gg',sequence:['g','g'],action:'Top',context:'Vim',category:'test',difficulty:1,mnemonic:''}]};

test('trainer waits for full sequence, ignores repeats, records once, and retries cleanly', async()=>{
  await mount(<Trainer drillSet={set} maxQuestions={1}/>);await click('Drill');await click('Press the keys');
  await key('g');expect(win.document.querySelector('.kb-feedback')).toBeNull();
  await key('g',{repeat:true});expect(win.document.querySelector('.kb-feedback')).toBeNull();
  await key('g');expect(win.document.querySelector('.kb-feedback--correct')).not.toBeNull();
  const saved=JSON.parse(win.localStorage.getItem('dotfiles-mastery-progress')!);
  expect(saved.drills.totalDrills).toBe(1);expect(saved.drills.keybindings['fixture:gg'].repetitions).toBe(1);
  await click('See Results');await click('Try Again');expect(win.document.querySelector('.kb-summary')).toBeNull();
  await click('Press the keys');expect(win.document.querySelector<HappyInput>('.kb-key-input')!.value).toBe('');
});

test('typed fallback evaluates sequences without requiring reserved shortcuts', async()=>{
  await mount(<Trainer drillSet={{...set,drills:[{...set.drills[0],keys:'Ctrl+b |',sequence:['Ctrl+b','|']}]}} maxQuestions={1}/>);
  await click('Test');await click('Press the keys');
  await act(async()=>win.document.querySelector<HappyInput>('input[type=checkbox]')!.click());
  const input=win.document.querySelector<HappyInput>('.kb-key-input')!;
  await act(async()=>{
    const setter=Object.getOwnPropertyDescriptor(win.HTMLInputElement.prototype,'value')!.set!;
    setter.call(input,'Ctrl+b |');input.dispatchEvent(new win.Event('input',{bubbles:true}));input.dispatchEvent(new win.Event('change',{bubbles:true}));
  });
  await click('Check answer');expect(win.document.querySelector('.kb-feedback--correct')).not.toBeNull();
});

test('every hint, including a single hint, becomes visible', async()=>{
  await mount(<VimPractice exercise={{id:'x',title:'X',description:'',initialContent:'a',targetContent:'b',commands:[],hints:['first','last']}}/>);
  await click('Show Hint');await click('Next Hint');expect(win.document.querySelectorAll('.vim-practice-hint').length).toBe(2);
  expect([...win.document.querySelectorAll('button')].some(b=>b.textContent==='Next Hint')).toBe(false);
});
