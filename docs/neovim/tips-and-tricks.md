# Tips & Tricks

Pro tips for maximum productivity with this Neovim configuration.

## Productivity Boosters

### Use Relative Line Numbers

Already enabled! Jump efficiently:
```
5j      " Jump down 5 lines (you can see it's line 5 below)
3k      " Jump up 3 lines
d7j     " Delete current + 7 lines down
y4k     " Yank 4 lines up
```

### Master the Dot Command

`.` repeats your last change. Design your edits to be repeatable!

**Bad:**
```javascript
// Adding semicolons one by one:
A;<Esc>           " Add semicolon
j                 " Down
A;<Esc>           " Add semicolon again (different command)
```

**Good:**
```javascript
// Design for repeat:
A;<Esc>           " Add semicolon
j.                " Down and repeat
j.                " Down and repeat
```

### Combine Counts with Everything

```
3w      " Forward 3 words
2dw     " Delete 2 words
5dd     " Delete 5 lines
3p      " Paste 3 times
4x      " Delete 4 characters
10j     " Jump 10 lines down
```

### Use Text Objects for Surgical Editing

Instead of precision cursor placement, use text objects:

**Before (hard):**
```javascript
const message = "Hello, World!";
// Need to change "Hello, World!" to something else
// Traditional: Position cursor at H, then select manually
```

**After (easy):**
```javascript
const message = "Hello, World!";
// Just: ci"
// Changes everything inside quotes, regardless of cursor position
```

**More examples:**
```javascript
function getData(user, config) {
    // ...lots of code...
}

// Anywhere in function: di{ (delete function body)
// On function name: dap (delete entire paragraph/function)
// On parameter: diw (delete parameter name)
```

## Search & Navigation Tricks

### Quick Symbol Search

```vim
*           " Search forward for word under cursor
#           " Search backward for word under cursor
gd          " LSP: Jump to definition
gR          " LSP: Find all usages
```

**Workflow:**
1. Place cursor on variable
2. Press `*` to highlight all occurrences
3. Press `n` to jump through them
4. Press `gR` to see all in Telescope

### Navigate by Searching

Don't scroll! Search:
```vim
/return<CR>      " Jump to next 'return'
/function.*get   " Jump to function with 'get' in name
?import          " Search backwards for import
```

### Use Marks for Common Locations

```vim
" In main file:
mm          " Mark as 'm' (main)

" In test file:
mt          " Mark as 't' (test)

" Jump between them:
'm          " Go to main
't          " Go to test
```

**Global marks for cross-file navigation:**
```vim
mM          " Global mark M (anywhere in project)
'M          " Jump back to mark M (even from different file)
```

### Telescope Power User Tips

**Recent files are your friend:**
```vim
<leader>pr       " Show recent files
" Then just 'j' a few times and Enter
" Faster than finding by name!
```

**Search word under cursor:**
```vim
<leader>pWs      " Grep for word under cursor
" Instantly find all usages
```

**Telescope from visual selection:**
```vim
" Select text in visual mode
:Telescope grep_string
" Searches for selected text!
```

## Editing Tricks

### Multiple Cursors (Visual Block)

```javascript
// Add comment to multiple lines:
const foo = 1;
const bar = 2;
const baz = 3;

// Workflow:
1. Ctrl-v        " Visual block
2. jj            " Select 3 lines
3. I             " Insert at start
4. // <Esc>      " Applied to all!

// Result:
// const foo = 1;
// const bar = 2;
// const baz = 3;
```

### Change/Delete Until Character

```javascript
// Change everything until semicolon:
const message = "Hello, World";
              ^
ct;          " Change till semicolon
" Type new text
// const message = "new text";
```

### Swap Two Words

```javascript
const user name = getData();
      ^^^^ ^^^^

// Cursor on "user":
dawwP        " Delete word, move word, paste before
// Result: const name user = getData();
```

### Duplicate Lines Quickly

```javascript
const foo = "bar";

// Duplicate:
yyp          " Yank line, paste below

// Duplicate multiple:
3yyp         " Yank 3 lines, paste below
```

### Join Lines Smartly

```javascript
// Ugly formatting:
const message =
    "Hello, World!";

// Join:
J            " Joins next line with space
// Result: const message = "Hello, World!";
```

### Change Inside Matching Pairs

```javascript
const config = {
    name: "old",
    value: 123
};

// Cursor anywhere inside braces:
ci{          " Change inside braces
// Type new content

// Works with: ( ) [ ] { } < > " ' ` and more!
```

## LSP Power Moves

### Quick Documentation Lookup

```javascript
Math.floor(x)
     ^
K            " Shows docs inline
K K          " Press twice to enter doc window (scrollable)
q            " Close doc window
```

**Use liberally!** It's faster than switching to browser.

### Code Action on Error

```javascript
// Red underline on error
const user = getUser();

<leader>vca
// Shows:
// 1. Import getUser
// 2. Create function getUser
// 3. Ignore error
// Select with j/k, Enter to apply
```

### Rename Across Files

```javascript
// Old name: getUserData
// Want: fetchUserData

1. Cursor on getUserData (anywhere)
2. <leader>rn
3. Type: fetchUserData
4. Enter

// Renames in ALL files in project!
// Works across JavaScript, TypeScript, imports, exports, etc.
```

### Find All Usages Then Refactor

```javascript
1. gR                  " Find all usages in Telescope
2. Review each one     " Understand context
3. <leader>rn          " Rename if needed
   OR
   Manual edits        " If rename isn't enough
```

## Project & Workspace Tricks

### Project Switching Workflow

```vim
<leader>pp           " Switch project
" Type partial name
" Hit Enter
" Auto-restores last session!
```

**Pro tip:** Combined with git branches:
```bash
# Switch branch in terminal
git checkout feature-branch

# Open nvim
nvim
# Separate session per branch automatically!
```

### Quick Session Management

```vim
" Working on feature:
<leader>ws           " Save session

" Context switch:
<leader>pp           " Switch to different project
" Work on other project...

" Back to feature:
<leader>wf           " Find sessions
" Select your session
" Exactly where you left off!
```

### Multi-Project Workflow

Use tmux + sessions:
```bash
# Terminal 1:
cd ~/project-a && nvim

# Terminal 2 (tmux):
prefix c                 # New tmux window
cd ~/project-b && nvim

# Switch with: prefix + n/p
```

## Macro Magic

### Record Once, Repeat Many

```javascript
// Format 20 function parameters:
// Before:
function getData(user,config,options,cache,transform,...more) {}

// Macro:
qa               " Record to register 'a'
f,               " Find comma
s, <Esc>         " Replace with comma+space
q                " Stop recording

10@a             " Repeat 10 times
// Result:
function getData(user, config, options, cache, transform, ...more) {}
```

### Edit Macro

```vim
" View macro:
:reg a           " Show contents of register 'a'

" Edit:
:let @a='...'    " Manually edit macro string

" Or paste, edit, yank back:
"ap              " Paste macro
" Edit in buffer
"ayy             " Yank back to register 'a'
```

### Recursive Macro

```javascript
// Process all functions in file:
let @a='/function^M@a'
" ^M = Enter key (Ctrl-v Enter in insert mode)
" Searches for "function" then calls itself

@a               " Run once, processes entire file!
```

## Window & Buffer Management

### Quick Window Creation

```vim
:vs              " Vertical split
<leader>ff       " Find file
" Opens in new split!

:sp              " Horizontal split
<leader>ff       " Find file
```

### Window Navigation Flow

```vim
" Four windows open:
Ctrl-h           " Left window
Ctrl-l           " Right window
Ctrl-j           " Bottom window
Ctrl-k           " Top window

" Works with tmux panes too!
```

### Buffer Switching

```vim
:ls              " List buffers
:b<tab>          " Cycle through buffer names
:b<partial>      " Jump to buffer by partial name

" Examples:
:b user<tab>     " Goes to user.js
:b#              " Go to alternate buffer (last one)
```

## Command-Line Tricks

### Command History

```vim
:              " Enter command mode
<Up/Down>      " Cycle through command history
Ctrl-p/n       " Alternative cycling
```

### Command Completion

```vim
:col<tab>      " Completes to :colorscheme
:b use<tab>    " Completes to buffer names matching "use"
:e **/*user<tab> " File name completion
```

### Range Shortcuts

```vim
:.,$s/old/new/g    " Current line to end
:1,.s/old/new/g    " Start to current line
:'<,'>s/old/new/g  " Visual selection (auto-inserted)
:g/pattern/d       " Delete all lines matching pattern
```

## Performance Optimization

### Disable Features for Large Files

```vim
" For 10MB+ files:
:syntax off            " Disable syntax highlighting
:set noswapfile        " Disable swap
:set nowrap            " Disable line wrap
:LspStop               " Stop LSP
```

### Lazy Load Everything

Check which plugins load on startup:
```vim
:Lazy profile
" Look for plugins with slow startup
" Add 'event = "VeryLazy"' to their config
```

### Use Direct Commands

```vim
" Slower:
<leader>ff<search><CR>

" Faster (if you know path):
:e path/to/file<tab>
```

## Git Integration

### Quick Status Check

Your statusline shows git branch and changes!

Look for:
- Branch name in statusline
- Modified indicators
- +/- lines changed

### Lazygit from Tmux

```bash
# In tmux:
prefix + o         # Opens lazygit in floating window
```

### Git Blame in Statusline

Already shows current line's last commit!

## Advanced Search Patterns

### Regex Search

```vim
/function \w\+Data    " Find "function" + word + "Data"
/^\s*const            " Lines starting with const (any indent)
/return.*;$           " Return statements with semicolon
/\<TODO\>             " Exact word TODO
```

### Search and Operate

```vim
" Delete all console.log:
:g/console\.log/d

" Comment all TODOs:
:g/TODO/norm gcc

" Change all var to const:
:%s/\<var\>/const/g
```

## Terminal Integration

### Quick Terminal

```vim
:term                " Open terminal in split
i                    " Enter terminal mode
Ctrl-\ Ctrl-n        " Exit to normal mode
:q                   " Close terminal
```

### Run Command and Capture Output

```vim
:r!ls                " Insert ls output into buffer
:r!git log -5        " Insert last 5 commits
:r!date              " Insert current date
```

## Pro Workflows

### Workflow: Learn New Codebase

```vim
1. <leader>pp              " Open project
2. <leader>fg              " Grep for "main" or entry point
3. gd                      " Jump to definitions
4. K                       " Read documentation
5. mM                      " Mark important places
6. gR                      " Find usages to understand patterns
```

### Workflow: Refactoring

```vim
1. gR                      " Find all usages
2. Review in Telescope     " Understand scope
3. <leader>rn              " Safe rename
   OR
4. :%s/old/new/gc          " Manual with confirmation
```

### Workflow: Debugging

```vim
1. <leader>fg error        " Find error message
2. gd                      " Jump to source
3. di{                     " Delete function body
4. o                       " New line
5. console.log(            " Add logging
6. Test...
7. u u u                   " Undo changes
```

### Workflow: Code Review

```vim
1. <leader>pp              " Open project
2. <leader>pr              " Recent files (what changed)
3. ]c / [c                 " Navigate changes (if diff)
4. K                       " Check docs for unfamiliar code
5. <leader>xw              " Check for errors
```

## Muscle Memory Builders

Practice these daily:

### Day 1-7: Basic Motions
- `w` `b` `e` for word movement
- `0` `$` for line movement
- `{` `}` for paragraph movement

### Day 8-14: Text Objects
- `ciw` `diw` `yiw` for words
- `ci"` `di"` for quotes
- `ci(` `di(` for parentheses

### Day 15-21: Operators + Motions
- `d{motion}` delete
- `c{motion}` change
- `y{motion}` yank
- Practice combinations!

### Day 22-30: LSP Features
- `gd` and `Ctrl-o` constantly
- `K` on everything
- `<leader>rn` for refactoring
- `<leader>vca` for quick fixes

## Final Pro Tips

1. **Design for `.` (dot command)** - Make edits repeatable
2. **Think in text objects** - Not cursor positions
3. **Use relative line numbers** - Jump directly
4. **Search, don't scroll** - Let computer find it
5. **Mark important places** - Don't waste time navigating
6. **LSP features >> manual search** - Use `gd`, `gR`, `K`
7. **Learn one thing at a time** - Master before adding more
8. **Practice deliberately** - Not just hoping to learn by osmosis
9. **Customize gradually** - Understand before changing
10. **The best key is the one you remember** - Don't over-optimize

---

**Remember:** Speed comes from reducing mental overhead, not faster fingers. Master the patterns, and velocity follows naturally.

**Challenge:** Each week, pick one trick from this doc and force yourself to use it 100 times. By week's end, it'll be muscle memory!
