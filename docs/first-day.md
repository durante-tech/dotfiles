# Your First Day with Neovim

A structured guide to get you productive on day one.

## Morning: The Fundamentals (2-3 hours)

### Hour 1: Understanding Modes

Neovim's power comes from modal editing. Master these first.

**Exercise 1: Mode Practice (15 minutes)**
```vim
1. Open Neovim: nvim
2. Press i
   - Notice "-- INSERT --" at bottom
   - Type: Hello, World!
   - Press Esc
   - Notice INSERT disappears

3. Practice transition:
   - i (insert) → type → Esc → i → type → Esc
   - Repeat 10 times until natural
```

**Exercise 2: Movement in NORMAL Mode (30 minutes)**
```vim
1. Create practice file:
   nvim practice.txt

2. Enter INSERT mode (i), paste this:
   The quick brown fox jumps over the lazy dog.
   Pack my box with five dozen liquor jugs.
   How vexingly quick daft zebras jump!

3. Press Esc (NORMAL mode)

4. Practice these movements 10 times each:
   - h h h h (left)
   - l l l l (right)
   - j j j (down)
   - k k (up)

5. Practice these 5 times each:
   - w (next word)
   - b (back word)
   - 0 (start of line)
   - $ (end of line)
   - gg (top of file)
   - G (bottom of file)
```

**Exercise 3: Basic Editing (15 minutes)**
```vim
Still in practice.txt:

1. Go to line 1: gg
2. Delete line: dd
3. Undo: u
4. Redo: Ctrl-r

5. Go to first word:
   - Type: ciw
   - Type: CHANGED
   - Press Esc
   - See "The" became "CHANGED"

6. Undo (u) and try:
   - yy (copy line)
   - p (paste below)
   - Now you have duplicate!

7. Practice: dd, yy, p, u until comfortable
```

### Hour 2: Essential Operations

**Exercise 4: Finding Files (15 minutes)**
```vim
1. Navigate to a project:
   cd ~/projects/your-project
   nvim

2. Find files by name:
   <leader>ff
   (Remember: <leader> = Space key)

3. Type partial filename
   - Notice fuzzy matching!
   - Use Ctrl-j/k to move
   - Press Enter to open

4. Try finding 3 different files
```

**Exercise 5: Searching in Files (15 minutes)**
```vim
1. Search for text:
   <leader>fg

2. Type a common word (like "function" or "const")

3. Browse results:
   - Ctrl-j (down)
   - Ctrl-k (up)
   - Enter to jump to file

4. Once in file:
   - Ctrl-o to jump back to Telescope
   - Or Esc to close
```

**Exercise 6: Editing a Real File (30 minutes)**
```vim
Workflow: Find, Open, Edit, Save

1. <leader>ff
2. Find a file you want to edit
3. Enter

4. Make a small change:
   - Find word to change: /oldword Enter
   - Press: ciw
   - Type new word
   - Esc

5. Save: :w

6. If you messed up: u (undo)
7. Quit: :q
```

## Lunch Break

Take a break! Let your muscle memory settle.

## Afternoon: Real Work (2-3 hours)

### Hour 3: Code Navigation

**Exercise 7: Using LSP (30 minutes)**
```vim
1. Open a code file:
   <leader>ff
   Find a .js, .ts, .go, or .lua file

2. Find a function call:
   /function_name

3. Jump to definition:
   - Cursor on function name
   - Press: gd
   - Jumps to where it's defined!

4. Jump back:
   Ctrl-o

5. Find all usages:
   - Cursor on function name
   - Press: gR
   - See all places it's called!

6. Read documentation:
   - Cursor on any function
   - Press: K (capital K)
   - Read inline docs!
```

**Exercise 8: Window Management (15 minutes)**
```vim
1. Open two files side by side:
   :vs
   <leader>ff
   (opens in new split)

2. Navigate between them:
   Ctrl-h (left window)
   Ctrl-l (right window)

3. Try vertical and horizontal:
   :vs (vertical)
   :sp (horizontal)

4. Close extra windows:
   :q (close current)
   :only (close all except current)
```

**Exercise 9: Visual Mode (15 minutes)**
```vim
1. Open any code file

2. Select lines:
   V (capital V)
   j j j (select 3 lines)
   Press d (delete)
   Press u (undo)

3. Select text:
   v (lowercase v)
   w w w (select 3 words)
   Press y (yank/copy)
   Press p (paste)

4. Block selection:
   Ctrl-v
   j j (down)
   l l l (right)
   Press I
   Type //
   Esc (applies to all lines!)
```

### Hour 4: Practical Workflows

**Exercise 10: Bug Fix Simulation (30 minutes)**
```vim
Scenario: Fix a typo across multiple files

1. Find the typo:
   <leader>fg
   Type the misspelled word
   Enter

2. Review each occurrence:
   - Telescope shows all matches
   - Navigate with Ctrl-j/k
   - Enter to open file

3. Fix each one:
   - Cursor on word
   - ciw (change word)
   - Type correction
   - Esc
   - :w (save)

4. Find next:
   <leader>pr (recent files)
   Open next file with typo
   Repeat!
```

**Exercise 11: Refactoring (30 minutes)**
```vim
Scenario: Rename a variable

1. Find the variable:
   <leader>fg variable_name

2. Jump to definition:
   - Open file from Telescope
   - gd on variable

3. Rename everywhere:
   <leader>rn
   Type new name
   Enter
   (LSP renames in ALL files!)

4. Verify:
   <leader>fg old_name
   Should find nothing!
   <leader>fg new_name
   Should find all occurrences!
```

### Hour 5: Building Muscle Memory

**Exercise 12: Timed Challenges (30 minutes)**

**Challenge 1: Speed Opening (5 minutes)**
```
Timer: 5 minutes
Goal: Open 10 different files as fast as possible

<leader>ff → type → Enter (repeat 10 times)

Track your time!
```

**Challenge 2: Quick Edits (10 minutes)**
```
Open any code file

1. Find word "const" (/)
2. Change it to "let" (ciw)
3. Undo (u)
4. Repeat with 5 different words

Time yourself!
```

**Challenge 3: Navigation Speed (10 minutes)**
```
Open a file

1. Jump to function definition (gd)
2. Jump back (Ctrl-o)
3. Find all usages (gR)
4. Jump to one (Enter)
5. Jump back (Ctrl-o)

Repeat with 5 different functions
Time yourself!
```

**Challenge 4: Text Object Mastery (5 minutes)**
```
Find code with:
- Quotes: "text"
- Parentheses: (args)
- Braces: { code }

Practice:
- ci" (change inside quotes)
- da( (delete around parens)
- yi{ (yank inside braces)

Do each 5 times!
```

## Evening: Review & Setup (1 hour)

### Personalization

**Set Your Preferences:**
```vim
1. Try different colorschemes:
   <leader>ths
   Browse with j/k
   Enter to apply

2. Explore your setup:
   :Lazy
   See all plugins installed

3. Check LSP status:
   :LspInfo
   :Mason
   (See available language servers)
```

### Tomorrow's Preparation

**Create a Cheatsheet:**
Write down on paper (yes, paper!):

```
My Top 10 Keys:
1. <leader>ff - Find files
2. <leader>fg - Grep
3. gd - Definition
4. K - Docs
5. ciw - Change word
6. dd - Delete line
7. :w - Save
8. u - Undo
9. Ctrl-o - Back
10. <leader>rn - Rename
```

**Set a Daily Goal:**
```
Tomorrow I will practice:
- [ ] Text objects (ciw, ci", ci{) 20 times
- [ ] LSP features (gd, K, gR) 10 times
- [ ] Searching (<leader>fg) for every lookup
- [ ] NO mouse usage for navigation
```

## End of Day Checklist

- [ ] Can enter/exit INSERT mode without thinking
- [ ] Can open files with `<leader>ff`
- [ ] Can search text with `<leader>fg`
- [ ] Can save (`:w`) and quit (`:q`)
- [ ] Can undo (`u`) mistakes
- [ ] Can navigate with `hjkl` comfortably
- [ ] Have used `gd` to jump to a definition
- [ ] Have used `K` to read documentation
- [ ] Can change a word with `ciw`
- [ ] Can delete a line with `dd`

## What You've Accomplished

Today you:
✅ Mastered modal editing basics
✅ Learned essential movement keys
✅ Opened and edited real files
✅ Used fuzzy finding and search
✅ Navigated code with LSP
✅ Performed basic refactoring
✅ Built initial muscle memory

## Tomorrow's Focus

**Week 1 Goals:**
- Day 2: Master text objects (`ciw`, `ci"`, `ci(`, `ci{`)
- Day 3: Perfect navigation (word motions, line jumps, search)
- Day 4: Window & buffer management
- Day 5: Advanced editing (visual mode, macros basics)
- Day 6-7: Practice on real projects

**Resources for Tomorrow:**
- [Daily Cheatsheet](daily-cheatsheet.md) - Keep this open!
- [Editing Workflows](workflows/editing.md) - Deep dive
- [Navigation Workflows](workflows/navigation.md) - Master movement

## Common First Day Questions

**Q: "I keep accidentally entering modes I don't want!"**
A: Press `Esc` liberally. It always returns you to NORMAL mode. Can't hurt!

**Q: "This is slower than my old editor..."**
A: Normal for day 1! Speed comes in week 2-3. Focus on correctness first.

**Q: "Should I use the mouse?"**
A: Try to avoid it! Keyboard-only builds muscle memory faster.

**Q: "What if I forget a key?"**
A: Keep [Daily Cheatsheet](daily-cheatsheet.md) open on second monitor or printed.

**Q: "Can I use my old editor for urgent work?"**
A: Yes! Use Neovim for learning, fallback for deadlines. You'll transition naturally.

**Q: "How long until I'm faster?"**
A: Week 1: Slower (learning)
   Week 2: Breaking even
   Week 3-4: Noticeably faster
   Month 2+: Significantly faster

## Celebrate!

You completed day 1! That's the hardest part. Every day gets easier and faster.

**Tomorrow, you'll be amazed at how much more natural it feels.**

---

**Final Tip:** Don't try to learn everything at once. Master one workflow per day. Slow progress is still progress!

**See you tomorrow! Check out [Daily Cheatsheet](daily-cheatsheet.md) before bed to review.**
