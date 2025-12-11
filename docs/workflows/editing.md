# Editing Workflows

Master efficient code editing with Neovim's powerful modal editing system.

## Philosophy

Vim editing is built around composability:
```
[count] [operator] [motion/text-object]
```

Example: `3dw` = delete 3 words = `3` (count) + `d` (delete) + `w` (word motion)

## Basic Editing Operations

### Entering INSERT Mode

| Keys | Action | Use Case |
|------|--------|----------|
| `i` | Insert before cursor | Most common |
| `a` | Append after cursor | Add to end of word |
| `I` | Insert at line start | Add at beginning |
| `A` | Append at line end | Add semicolons, commas |
| `o` | Open line below | New line after current |
| `O` | Open line above | New line before current |
| `gi` | Insert at last edit position | Continue where you left off |
| `s` | Substitute character | Replace char and insert |
| `S` | Substitute line | Replace whole line |

**Pro Tip:** Use `A` for adding semicolons/commas at line end instead of `$a`.

### Deleting (Cut)

| Keys | Action |
|------|--------|
| `x` | Delete character under cursor |
| `X` | Delete character before cursor |
| `dd` | Delete line |
| `D` | Delete to end of line |
| `dw` | Delete word |
| `diw` | Delete inner word (regardless of cursor position) |
| `daw` | Delete around word (includes surrounding space) |
| `d$` | Delete to end of line |
| `d0` | Delete to start of line |
| `dgg` | Delete to top of file |
| `dG` | Delete to bottom of file |

### Changing (Delete + Insert)

| Keys | Action |
|------|--------|
| `cc` | Change line |
| `C` | Change to end of line |
| `cw` | Change word |
| `ciw` | Change inner word |
| `caw` | Change around word |
| `ci"` | Change inside quotes |
| `ci(` | Change inside parentheses |
| `cit` | Change inside HTML tag |
| `c$` | Change to end of line |

**Pro Tip:** `c` commands are great for refactoring! `ciw` replaces the word under cursor.

### Copying (Yanking)

| Keys | Action |
|------|--------|
| `yy` | Yank line |
| `Y` | Yank line (same as `yy`) |
| `yw` | Yank word |
| `yiw` | Yank inner word |
| `yaw` | Yank around word |
| `y$` | Yank to end of line |
| `ygg` | Yank to top of file |
| `yG` | Yank to bottom of file |

### Pasting

| Keys | Action |
|------|--------|
| `p` | Paste after cursor/line |
| `P` | Paste before cursor/line |
| `gp` | Paste and move cursor after |
| `gP` | Paste before and move cursor after |

**Pro Tip:** Yank from one file, switch files with `<leader>ff`, then paste!

## Text Objects

Text objects define "boundaries" for operations. They're used with operators.

### Inner vs Around

- **Inner (`i`)**: Excludes surrounding delimiters/whitespace
- **Around (`a`)**: Includes surrounding delimiters/whitespace

### Common Text Objects

| Text Object | Description | Example |
|-------------|-------------|---------|
| `iw` / `aw` | inner/around word | `ciw` change word |
| `iW` / `aW` | inner/around WORD (includes punctuation) | `daW` delete WORD |
| `is` / `as` | inner/around sentence | `das` delete sentence |
| `ip` / `ap` | inner/around paragraph | `yap` yank paragraph |
| `i"` / `a"` | inside/around double quotes | `ci"` change quoted text |
| `i'` / `a'` | inside/around single quotes | `di'` delete quoted text |
| `i`` / `a`` | inside/around backticks | `ci`` change template string |
| `i(` / `a(` | inside/around parentheses | `da(` delete with parens |
| `i[` / `a[` | inside/around brackets | `yi[` yank array contents |
| `i{` / `a{` | inside/around braces | `di{` delete function body |
| `i<` / `a<` | inside/around angle brackets | `ca<` change generics |
| `it` / `at` | inside/around HTML/XML tag | `dit` delete tag contents |

### Real-World Examples

```javascript
// Cursor on "foo" anywhere in the word
const foo = "bar";

ciw → changes "foo" to whatever you type
caw → changes "foo " (with space) to whatever you type
yiw → copies "foo"

// Cursor inside quotes
const message = "Hello, World!";

ci" → changes "Hello, World!" to new text
di" → deletes "Hello, World!" (quotes remain)
da" → deletes "Hello, World!" including quotes
yi" → copies "Hello, World!"

// Cursor inside function
function greet() {
    console.log("Hello");
    return true;
}

di{ → deletes function body only
da{ → deletes including braces
yab → yanks entire block with braces
```

## Visual Mode

Visual mode lets you select text visually before operating on it.

### Entering Visual Mode

| Keys | Mode | Description |
|------|------|-------------|
| `v` | Character-wise | Select individual characters |
| `V` | Line-wise | Select whole lines |
| `Ctrl-v` | Block-wise | Select rectangular block |
| `gv` | - | Reselect last visual selection |

### Operations in Visual Mode

Once in visual mode:
1. Move to select text (`hjkl`, `w`, `b`, etc.)
2. Perform operation:
   - `d` - Delete selection
   - `c` - Change selection
   - `y` - Yank selection
   - `gc` - Comment selection
   - `>` - Indent right
   - `<` - Indent left
   - `=` - Auto-indent

### Visual Block Mode (Ctrl-v) - Multi-Cursor Power!

Visual block mode is Vim's answer to multi-cursor editing. It's **incredibly powerful** for batch edits.

**Think of it as:** Selecting a rectangular region and operating on all lines at once.

#### Basic Visual Block

**Enter block mode:**
```
Ctrl-v          " Start visual block mode
```

**Select:**
```
j/k             " Extend selection down/up
h/l             " Extend selection left/right
w/b             " Jump by words
$               " To end of lines
0               " To start of lines
```

**Operate:**
```
d               " Delete block
c               " Change block (type once, applies to all)
y               " Yank block
I               " Insert before block (applies to all lines)
A               " Append after block (applies to all lines)
r{char}         " Replace all with character
>               " Indent block right
<               " Indent block left
```

#### Real-World Example 1: Your AeroSpace Config

**Scenario:** Change 4 lines from `DEV-SECOND` to `PORTRAIT-MONITOR`

```toml
N = '^DEV-SECOND$'    # Want to change this
M = '^DEV-SECOND$'    # And this
F = '^DEV-SECOND$'    # And this
E = '^DEV-SECOND$'    # And this
```

**Pro Method:**
```vim
1. /DEV-SECOND         " Search for first occurrence
2. Ctrl-v              " Visual block mode
3. 3j                  " Select down 3 lines (4 total)
4. e                   " Extend to end of word
5. c                   " Change (delete and enter insert)
6. PORTRAIT-MONITOR    " Type once
7. Esc                 " Applies to ALL 4 lines!
```

**Result:**
```toml
N = '^PORTRAIT-MONITOR$'
M = '^PORTRAIT-MONITOR$'
F = '^PORTRAIT-MONITOR$'
E = '^PORTRAIT-MONITOR$'
```

Done in **7 keystrokes**! 🚀

#### Real-World Example 2: Add Comments to Multiple Lines

**Before:**
```javascript
const user = getUser();
const posts = getPosts();
const likes = getLikes();
const follows = getFollows();
```

**Add // at start:**
```vim
1. Ctrl-v              " Visual block
2. 3j                  " Select 4 lines
3. I                   " Insert at start (capital I)
4. // <Space>          " Type comment
5. Esc                 " Applies to all!
```

**After:**
```javascript
// const user = getUser();
// const posts = getPosts();
// const likes = getLikes();
// const follows = getFollows();
```

#### Real-World Example 3: Add Semicolons to End

**Before:**
```javascript
const a = 1
const b = 2
const c = 3
const d = 4
```

**Add semicolons:**
```vim
1. Ctrl-v              " Visual block
2. 3j                  " Select 4 lines
3. $                   " Jump to end of lines
4. A                   " Append (capital A)
5. ;                   " Type semicolon
6. Esc                 " Applies to all!
```

**After:**
```javascript
const a = 1;
const b = 2;
const c = 3;
const d = 4;
```

#### Real-World Example 4: Delete Column

**Before:**
```python
x = 1  # comment
y = 2  # comment
z = 3  # comment
```

**Delete "# " from all:**
```vim
1. Position cursor on first #
2. Ctrl-v              " Visual block
3. 2j                  " Select 3 lines
4. l                   " Select "# " (2 chars)
5. d                   " Delete block
```

**After:**
```python
x = 1  comment
y = 2  comment
z = 3  comment
```

#### Real-World Example 5: Align Code

**Before:**
```javascript
const x = 1;
const foo = 2;
const longVariableName = 3;
```

**Insert spaces to align =:**
```vim
1. Position cursor after first =
2. Ctrl-v
3. 2j                  " Select 3 lines
4. I                   " Insert
5. <Space><Space>      " Add spaces
6. Esc
```

You can also use visual block to **delete** extra spaces for alignment!

#### Real-World Example 6: Change Multiple Words

**Before:**
```javascript
console.log(oldName);
doSomething(oldName);
return oldName;
process(oldName);
```

**Change "oldName" on all lines:**
```vim
1. Position cursor on first 'o' of oldName
2. Ctrl-v              " Visual block
3. 3j                  " Select 4 lines
4. e                   " Extend to end of word
5. c                   " Change
6. newName             " Type once
7. Esc                 " Applies to all 4!
```

#### Advanced: Non-Contiguous Characters

**Visual block can select COLUMNS, not just whole words!**

**Example: Extract first 3 characters:**
```
Original:
ABCDEF
GHIJKL
MNOPQR

1. Ctrl-v
2. 2j (select 3 lines)
3. 2l (select 3 chars wide)
4. y  (yank)

Result: Copies "ABC", "GHI", "MNO" as a block!
```

#### Pro Tips for Visual Block

**Tip 1: Use search to position**
```vim
/pattern               " Jump to first occurrence
Ctrl-v                 " Then start visual block
n                      " Jump to next (extends selection!)
```

**Tip 2: Combine with text objects**
```vim
Ctrl-v                 " Visual block
3j                     " Select lines
aw                     " Select "a word" on each line
c                      " Change all words
```

**Tip 3: Ragged selections work!**
```vim
// Works even if lines have different lengths:
const x = 1;
const veryLongVariableName = 2;
const y = 3;

Ctrl-v, 2j, $, A       " Append at end of each (different positions!)
```

**Tip 4: Repeat with dot command**
```vim
Ctrl-v                 " First block
jj                     " Select
c                      " Change
replacement            " Type
Esc

// Move to next block:
/pattern
.                      " Repeat! (works sometimes, depending on edit)
```

#### When Visual Block is PERFECT

✅ **Changing same word on multiple lines** (your aerospace example)
✅ **Adding/removing comments** (// at start of lines)
✅ **Adding punctuation** (; at end)
✅ **Deleting columns** (delete first N chars from all lines)
✅ **Adding prefixes** (adding "const " to variables)
✅ **Table editing** (align columns)
✅ **List reformatting** (add bullets, numbers)

#### Visual Block vs. Other Methods

| Task | Visual Block | Alternative | Winner |
|------|--------------|-------------|---------|
| Change same word on 4 lines | `Ctrl-v 3j e c` | `:g/pattern/s//new/` | Visual Block (visual) |
| Change word everywhere | `Ctrl-v` needs positioning | `:%s/old/new/g` | Substitute (global) |
| Add comment to 5 lines | `Ctrl-v 4j I // ` | `5gcc` (with plugin) | Visual Block |
| Align code | `Ctrl-v` with spaces | External formatter | Depends |

#### Keyboard Shortcuts Summary

| Keys | Action |
|------|--------|
| `Ctrl-v` | Enter visual block mode |
| `j/k` | Extend selection down/up |
| `h/l` | Extend selection left/right |
| `$` | Extend to end of lines |
| `e/w/b` | Extend by word motions |
| `I` | Insert before block (all lines) |
| `A` | Append after block (all lines) |
| `c` | Change block |
| `d` | Delete block |
| `y` | Yank block |
| `r{char}` | Replace all with char |
| `>` / `<` | Indent block |
| `gv` | Reselect last visual block |

#### Practice Challenge

Try these right now:

**Challenge 1: Add TODO comments**
```javascript
Fix this function
Refactor this part
Update this logic

// Your job: Add "// TODO: " before each
```

**Challenge 2: Change variable names**
```javascript
user.oldProp = 1;
data.oldProp = 2;
obj.oldProp = 3;

// Change "oldProp" to "newProp" on all lines
```

**Challenge 3: Add trailing commas**
```javascript
const data = {
  name: 'John'
  age: 30
  city: 'NYC'
}

// Add commas at end of each line
```

**Solutions:**
```vim
Challenge 1: Ctrl-v, 2j, I, // TODO: <Esc>
Challenge 2: /oldProp, Ctrl-v, 2j, e, c, newProp, Esc
Challenge 3: Ctrl-v, 2j, $, A, ,, Esc
```

## Repeating and Macros

### The Dot Command

`.` repeats the last change. This is incredibly powerful!

```javascript
// Add semicolons to multiple lines:
A;          // Append semicolon
Esc         // Back to normal
j           // Down one line
.           // Repeat (adds semicolon)
j.          // Repeat on next line
```

### Recording Macros

Macros let you record and replay a sequence of commands.

**Recording:**
1. `q{register}` - Start recording (e.g., `qa` uses register 'a')
2. Perform your commands
3. `q` - Stop recording

**Playing:**
- `@{register}` - Play macro once (e.g., `@a`)
- `@@` - Repeat last macro
- `10@a` - Play macro 10 times

**Example:**
```javascript
// Format multiple function parameters:
qa              // Start recording to 'a'
I    ^          // Add 4 spaces at start
A,^             // Add comma at end
j               // Move down
q               // Stop recording
5@a             // Repeat 5 times
```

## Advanced Editing Patterns

### Surround Operations

Add/change/delete surrounding characters:

```javascript
// Using visual mode:
viw    // Select word
S"     // Surround with quotes (if vim-surround installed)

// Or install mini.surround for:
sa + motion + char    // Add surround
sd + char             // Delete surround
sr + old + new        // Replace surround
```

### Case Conversion

| Keys | Action |
|------|--------|
| `~` | Toggle case of character |
| `g~{motion}` | Toggle case of motion |
| `gU{motion}` | Uppercase motion |
| `gu{motion}` | Lowercase motion |
| `gUU` | Uppercase line |
| `guu` | Lowercase line |

**Examples:**
- `gUiw` - Uppercase word
- `guap` - Lowercase paragraph
- `g~~` - Toggle case of line

### Indentation

| Keys | Action |
|------|--------|
| `>>` | Indent line right |
| `<<` | Indent line left |
| `==` | Auto-indent line |
| `={motion}` | Auto-indent motion |
| `gg=G` | Auto-indent entire file |
| `=ap` | Auto-indent paragraph |

**Visual Mode:**
- Select lines with `V`
- Press `>` to indent
- Press `.` to repeat

### Search and Replace

#### In Current Line
```vim
:s/old/new/        " Replace first occurrence
:s/old/new/g       " Replace all in line
```

#### In Entire File
```vim
:%s/old/new/g      " Replace all
:%s/old/new/gc     " Replace with confirmation
:%s/old/new/gi     " Case-insensitive replace
```

#### In Selection
1. Select lines with `V`
2. Type `:`  (automatically shows `:'<,'>`)
3. Enter `s/old/new/g`

#### In Range
```vim
:10,20s/old/new/g  " Lines 10-20
:.,$s/old/new/g    " Current line to end
```

## Commenting

This config has smart commenting:

| Keys | Action |
|------|--------|
| `gcc` | Toggle comment on line |
| `gc{motion}` | Comment motion |
| `gcap` | Comment paragraph |
| `gc` (visual) | Comment selection |

**Examples:**
```javascript
gcc     // Toggle comment current line
gc3j    // Comment current + 3 lines down
gcip    // Comment paragraph
```

## Practical Workflow Examples

### Scenario 1: Refactor Variable Name

```javascript
// Before: cursor on "oldName"
const oldName = getValue();
doSomething(oldName);
return oldName;

// Workflow:
1. <leader>rn          // LSP rename
2. Type newName
3. Enter               // Renames everywhere
```

### Scenario 2: Extract Multiple Lines

```javascript
// Extract lines 15-20 to new function:
1. :15,20d             // Delete (cut) lines
2. <leader>ff          // Find destination file
3. gg                  // Go to top
4. P                   // Paste before
```

### Scenario 3: Format JSON

```json
// Ugly JSON on one line
{"name":"John","age":30,"city":"New York"}

// Workflow:
1. V            // Select line
2. gq           // Format (if formatter installed)
// OR
1. ==           // Auto-indent based on syntax
```

### Scenario 4: Duplicate and Modify

```javascript
// Duplicate function and change name:
const getUser = () => { ... }

// Workflow:
1. yap          // Yank around paragraph (whole function)
2. p            // Paste below
3. /getUser     // Search for name
4. ciw          // Change word
5. getAdmin     // Type new name
```

### Scenario 5: Convert Array to Multi-line

```javascript
// Before:
const items = ['a', 'b', 'c', 'd'];

// Workflow:
1. f[           // Jump to [
2. %            // Jump to matching ]
3. i            // Insert before ]
4. Ctrl-v Esc   // Line break
5. ci[          // Change inside brackets
6. Ctrl-v Esc'a',Ctrl-v Esc'b',Ctrl-v Esc'c',Ctrl-v Esc'd'
// OR better: use visual block mode + macros
```

## Tips & Tricks

### Faster Word Changes
- `cw` changes from cursor to end of word
- `ciw` changes entire word (better for refactoring)

### Delete Without Yanking
- `"_dd` deletes without copying to clipboard
- `"_d{motion}` same for any motion

### Paste Over Selection
- `viwp` select word and paste over it
- Previous word goes to clipboard

### Join Lines
- `J` joins next line to current (removes newline)
- `3J` joins next 3 lines

### Repeat Insert Across Lines
```javascript
1. Ctrl-v         // Block select
2. Select lines
3. I              // Insert
4. Type text
5. Esc            // Applies to all
```

### Quick Number Increment/Decrement
- `Ctrl-a` increment number under cursor
- `Ctrl-x` decrement number under cursor
- `10 Ctrl-a` increment by 10

### Swap Two Words
```
diw        // Delete word
w          // Move to next word
viwp       // Select and paste over
```

---

**Practice makes perfect!** Focus on one pattern per day and practice it until it becomes muscle memory.

**Next:** [Navigation Workflows](navigation.md) to move efficiently through your code.
