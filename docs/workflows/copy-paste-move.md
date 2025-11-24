# Copy, Paste & Move Workflows

Master efficient text manipulation - copying, pasting, and moving content within and between files.

## Understanding Vim's Clipboard System

Vim has multiple registers (clipboards):
- **Unnamed register** (`""`): Default yank/delete/paste
- **System clipboard** (`"+` or `"*`): OS clipboard (copy/paste with other apps)
- **Named registers** (`"a` to `"z`): Your personal clipboards
- **Numbered registers** (`"0` to `"9`): Automatic history

## Basic Copy & Paste

### Copy (Yank)

| Keys | Action |
|------|--------|
| `yy` | Yank current line |
| `Y` | Yank current line (same as `yy`) |
| `y{motion}` | Yank motion |
| `yw` | Yank word |
| `yiw` | Yank inner word |
| `y$` | Yank to end of line |
| `y^` | Yank to start of line |
| `ygg` | Yank from here to top of file |
| `yG` | Yank from here to bottom of file |
| `yap` | Yank around paragraph |
| `yi{` | Yank inside braces |
| `ya"` | Yank around quotes (including quotes) |

### Paste

| Keys | Action |
|------|--------|
| `p` | Paste after cursor/below line |
| `P` | Paste before cursor/above line |
| `gp` | Paste and move cursor after pasted text |
| `gP` | Paste before and move cursor after |
| `]p` | Paste and adjust indentation |

### Delete (Cut)

Deleting in Vim automatically copies to register:

| Keys | Action |
|------|--------|
| `dd` | Delete (cut) line |
| `D` | Delete to end of line |
| `d{motion}` | Delete motion |
| `diw` | Delete inner word |
| `di"` | Delete inside quotes |
| `dap` | Delete around paragraph |

## Your Most Common Pattern

### Pattern: Select All, Copy, Paste to Another File

**Method 1: Visual Selection (Small-Medium Files)**
```vim
" File 1: Source
1. gg              " Go to top
2. V               " Visual LINE mode
3. G               " Select to bottom (all lines selected)
4. y               " Yank (copy)

" File 2: Destination
5. <leader>ff      " Find file
6. (select file)
7. Enter           " Open
8. p               " Paste below cursor
   OR
8. gg              " Go to top (if you want to paste at top)
9. P               " Paste above
```

**Method 2: Using Ex Commands (Fast for Large Files)**
```vim
" File 1: Source
:%y                " Yank entire file

" File 2: Destination
<leader>ff         " Find file
(select and open)
gg                 " Go to top
p                  " Paste
```

**Method 3: System Clipboard (Works with OS)**
```vim
" File 1: Source
gg                 " Top
"+yG               " Yank to system clipboard to bottom
   OR
:%y+               " Yank entire file to system clipboard

" File 2: Destination (even in different Neovim instance!)
<leader>ff         " Find file
"+p                " Paste from system clipboard
```

### Pattern: Copy Line(s) from One File, Paste to Another

**Single Line:**
```vim
" Source file:
1. yy              " Yank line

" Destination file:
2. <leader>ff      " Find file
3. (open file)
4. /some pattern   " Find where to paste
5. p               " Paste below
```

**Multiple Lines:**
```vim
" Source file:
1. 5yy             " Yank 5 lines
   OR
1. V               " Visual mode
2. 4j              " Select 5 lines
3. y               " Yank

" Destination file:
4. <leader>ff      " Find file
5. p               " Paste
```

**Non-contiguous Lines (Advanced):**
```vim
" Yank to named register:
"ayy               " Yank line to register 'a'
j j                " Move down
"Ayy               " Append line to register 'a' (capital A)
j j
"Ayy               " Append another

" Paste from named register:
<leader>ff         " Find file
"ap                " Paste from register 'a'
```

### Pattern: Copy Section from Middle of File

```vim
" Source file:
1. /function getData  " Find section start
2. V                  " Visual LINE
3. }                  " Jump to end of section (or select with j/k)
4. y                  " Yank

" Destination file:
5. <leader>ff         " Find file
6. /insert here       " Find insertion point
7. p                  " Paste below
```

## Advanced Copy & Paste

### Using Named Registers (Multiple Clipboards)

Think of registers as multiple clipboards you can use simultaneously:

```vim
" Copy to specific registers:
"ayy               " Yank line to register 'a'
"byy               " Yank line to register 'b'
"cyy               " Yank line to register 'c'

" Paste from specific registers:
"ap                " Paste from register 'a'
"bp                " Paste from register 'b'
"cp                " Paste from register 'c'

" View registers:
:reg               " Show all registers
:reg abc           " Show specific registers
```

**Practical Example:**
```vim
" Gather snippets from multiple files:
" File 1:
"ayy                " Copy to 'a'

" File 2:
"byy                " Copy to 'b'

" File 3:
"cyy                " Copy to 'c'

" File 4 (destination):
"ap                 " Paste from 'a'
"bp                 " Paste from 'b'
"cp                 " Paste from 'c'
```

### Append to Register

```vim
"ayy                " Yank to register 'a'
j j
"Ayy                " Append to register 'a' (capital A!)
j j
"Ayy                " Append more

"ap                 " Paste all at once
```

### System Clipboard (Copy from/to Browser, etc.)

**Copy TO system clipboard:**
```vim
"+yy               " Yank line to clipboard
"+yG               " Yank to end to clipboard
"+yiw              " Yank word to clipboard

" Or in visual mode:
V                  " Select lines
"+y                " Copy to clipboard
```

**Paste FROM system clipboard:**
```vim
"+p                " Paste from clipboard after
"+P                " Paste from clipboard before

" In insert mode:
Ctrl-r +           " Paste from clipboard
```

**Practical Example:**
```vim
" Copy from browser:
1. Select text in browser
2. Ctrl-C (or Cmd-C on Mac)

" Paste in Neovim:
3. (In Neovim)
4. "+p                " Pastes from system clipboard!
```

### Yank History (Numbered Registers)

Vim keeps history of your last yanks:

```vim
:reg               " View registers
" Shows:
" "0 - Last yank
" "1 - Last delete
" "2 - Second last delete
" etc.

"0p                " Paste last yank (not delete!)
"1p                " Paste last delete
"2p                " Paste second last delete
```

**Why this matters:**
```vim
yy                 " Yank line (goes to "0)
dd                 " Delete line (overwrites unnamed, but "0 still has yank!)
p                  " Pastes deleted line (probably not what you want)
"0p                " Pastes the yanked line (what you wanted!)
```

## Moving Text

### Move Lines Up/Down

**Single Line:**
```vim
dd                 " Delete line
k                  " Up one line
p                  " Paste below (line moved up)

" Or move down:
dd                 " Delete line
j                  " Down one line
P                  " Paste above (line moved down)
```

**Multiple Lines:**
```vim
V                  " Visual mode
jjj                " Select 3 lines
d                  " Delete (cut)
}                  " Jump to destination
p                  " Paste
```

### Move Text Between Files

**Method 1: Cut and Paste**
```vim
" Source file:
dd                 " Delete (cut) line

" Destination file:
<leader>ff         " Find file
p                  " Paste
```

**Method 2: Named Register**
```vim
" Source file:
"add               " Delete to register 'a'

" Destination file:
<leader>ff
"ap                " Paste from 'a'

" Back to source:
u                  " Undo delete (line is back!)
```

### Swap Two Lines

```vim
ddp                " Delete line, paste below (swaps with next)
ddkP               " Delete line, up, paste above (swaps with previous)
```

### Swap Two Words

```vim
" Cursor on first word:
dawwP              " Delete around word, forward word, Paste before
```

### Move Block of Code

```vim
1. V               " Visual LINE
2. }               " Select to end of block
3. d               " Cut
4. /destination    " Find where to move
5. p               " Paste
```

## Practical Workflows

### Workflow 1: Duplicate Line

```vim
yy                 " Copy line
p                  " Paste below (duplicate!)

" Or duplicate above:
yyP                " Copy and paste above
```

### Workflow 2: Copy Function to Another File

```vim
" Source file:
1. /function getData   " Find function
2. V                   " Visual mode
3. ]m                  " Jump to end of function (or use })
4. y                   " Yank

" Destination file:
5. <leader>ff          " Find file
6. G                   " Go to end
7. p                   " Paste
```

### Workflow 3: Gather Imports from Multiple Files

```vim
" File 1:
1. /^import            " Find import
2. "ayy                " Yank to 'a'
3. n                   " Next import
4. "Ayy                " Append to 'a'

" File 2:
5. <leader>ff          " Open another file
6. /^import
7. "Ayy                " Append more

" Destination:
8. <leader>ff          " Open target file
9. gg                  " Top of file
10. "aP                " Paste all imports
```

### Workflow 4: Copy File Contents to Another

**Entire file:**
```vim
" Source:
:%y                    " Yank entire file

" Destination:
<leader>ff             " Open file
gg                     " Top
p                      " Paste
```

**Or using Ex command:**
```vim
" In destination file:
:r /path/to/source.js  " Read source file into current
```

### Workflow 5: Copy Multiple Blocks

```vim
" Use visual mode to gather:
V                      " Visual mode
}                      " Select block
"ay                    " Yank to 'a'

" Find next block:
/next pattern
V}
"Ay                    " Append to 'a'

" Paste all:
<leader>ff
"ap                    " Paste everything
```

### Workflow 6: Copy from External Editor

```vim
" In other editor (VSCode, browser, etc.):
Ctrl-C                 " Copy

" In Neovim:
"+p                    " Paste from system clipboard
```

### Workflow 7: Copy Code to Share

```vim
" Select code:
V                      " Visual mode
}                      " Select block
"+y                    " Copy to system clipboard

" Now paste in Slack/email/etc with Ctrl-V
```

## Visual Mode Selections

### Select All

```vim
ggVG                   " Top, visual LINE, bottom

" Or:
:%y                    " Yank all (no selection needed)
```

### Select Function/Block

```vim
V                      " Visual LINE
%                      " Jump to matching brace (selects function)

" Or:
va{                    " Visual around braces
```

### Select Paragraph

```vim
vap                    " Visual around paragraph
yap                    " Yank around paragraph
```

### Select Lines 10-50

```vim
:10,50y                " Yank lines 10-50

" Or visually:
:10                    " Go to line 10
V                      " Visual mode
:50                    " Extend to line 50
y                      " Yank
```

### Select Inside Quotes/Parens/Braces

```vim
vi"                    " Visual inside quotes
vi(                    " Visual inside parentheses
vi{                    " Visual inside braces
vi[                    " Visual inside brackets

" Then:
y                      " Yank
d                      " Delete
c                      " Change
```

## Tips & Tricks

### Paste Multiple Times

```vim
yy                     " Yank line
5p                     " Paste 5 times!
```

### Paste Over Selection

```vim
viw                    " Select word
p                      " Pastes over it
" Previous word goes to register
```

### Don't Overwrite Register When Deleting

```vim
"_dd                   " Delete to black hole register
" Doesn't overwrite your yanked text!
```

### Paste Without Auto-Indent Issues

```vim
:set paste             " Disable auto-indent
" Paste text (from +p or system)
:set nopaste           " Re-enable
```

### View What You Last Yanked

```vim
:reg "                 " View unnamed register
:reg 0                 " View last yank
```

### Exchange Two Selections

```vim
" Requires vim-exchange plugin, but workflow:
1. Visual select first
2. cx                  " Mark for exchange
3. Visual select second
4. cx                  " Exchanges them!
```

## Quick Reference

**Copy line to another file:**
```vim
yy → <leader>ff → p
```

**Copy all file contents:**
```vim
:%y → <leader>ff → p
```

**Copy to system clipboard:**
```vim
"+yy  (or  "+yG  for all)
```

**Paste from system clipboard:**
```vim
"+p
```

**Copy to named register:**
```vim
"ayy
```

**Paste from named register:**
```vim
"ap
```

**Move line up:**
```vim
ddkP
```

**Move line down:**
```vim
ddp
```

**Duplicate line:**
```vim
yyp
```

**Select all:**
```vim
ggVG  (or  :%y  to just yank)
```

**Paste last yank (not delete):**
```vim
"0p
```

---

**Pro Tip:** For your common pattern (copy all from one file, paste to another), the fastest is:
```vim
:%y → <leader>ff → gg → p
```

Or use system clipboard for maximum compatibility:
```vim
:%y+ → (switch files however) → "+p
```

**Remember:** Vim's clipboard is powerful! Use named registers (`"a-"z`) as multiple clipboards when working with multiple sources.

**Next:** [Window & Buffer Management](windows-buffers.md)
