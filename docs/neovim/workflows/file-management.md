# File Management Workflows

Complete guide to creating, moving, renaming, and managing files and directories in Neovim.

## File Explorer Overview

This config has **two file explorers**:

1. **MiniFiles** (`<leader>ee`) - Modern, Miller-column style explorer (Primary)
2. **Oil** (`-`) - Buffer-based file manipulation (Alternative)

Choose the one that fits your workflow! Both are powerful.

---

## MiniFiles - Primary File Explorer

MiniFiles shows your file system in a clean, column-based view.

### Opening MiniFiles

| Keys | Action |
|------|--------|
| `<leader>ee` | Toggle MiniFiles |
| `<leader>ef` | Open MiniFiles at current file location |

### Navigating in MiniFiles

| Keys | Action |
|------|--------|
| `j` / `k` | Move down/up in list |
| `Enter` or `L` | Enter directory or open file |
| `-` or `H` | Go to parent directory |
| `gg` / `G` | Top/bottom of list |
| `q` or `Esc` | Close MiniFiles |

### Creating Files & Directories in MiniFiles

MiniFiles works like editing a buffer - add lines, then synchronize!

**Create File:**
```vim
1. <leader>ee          " Open MiniFiles
2. Navigate to directory
3. Press i             " INSERT mode (edit like a buffer!)
4. Type: newfile.js    " Add new line with filename
5. Esc                 " Exit INSERT mode
6. Press =             " Synchronize (creates the file!)
```

**Create Directory:**
```vim
1. <leader>ee          " Open MiniFiles
2. Navigate to parent directory
3. Press i             " INSERT mode
4. Type: dirname/      " Trailing slash for directory!
5. Esc                 " Exit INSERT mode
6. Press =             " Synchronize (creates directory!)
```

**Create Nested Structure:**
```vim
1. <leader>ee
2. Navigate to location
3. Press i             " INSERT mode
4. Type (on separate lines):
   src/components/Button/
   src/components/Button/Button.tsx
   src/components/Button/index.ts
5. Esc                 " Exit INSERT mode
6. Press =             " Synchronize (creates all at once!)
```

### Deleting in MiniFiles

**Delete File:**
```vim
1. <leader>ee          " Open MiniFiles
2. Navigate to file
3. Press d             " Mark for deletion
4. Confirm             " Deletes file
```

**Delete Multiple:**
```vim
1. <leader>ee
2. Visual mode (V)
3. Select files (j/k)
4. Press d             " Deletes all selected
```

### Renaming in MiniFiles

**Rename File:**
```vim
1. <leader>ee          " Open MiniFiles
2. Navigate to file
3. Press r             " Rename
4. Type new name
5. Enter               " Renames
```

### Moving in MiniFiles

**Move File:**
```vim
1. <leader>ee          " Open MiniFiles
2. Navigate to file
3. Press m             " Cut/move
4. Navigate to destination
5. Press p             " Paste (moves file)
```

**Copy File:**
```vim
1. <leader>ee
2. Navigate to file
3. Press y             " Yank (copy)
4. Navigate to destination
5. Press p             " Paste (copies file)
```

### MiniFiles Workflow Example

**Create Component Structure:**
```vim
1. <leader>ee                       " Open MiniFiles
2. Navigate to src/components/
3. Press i                          " INSERT mode
4. Type on separate lines:
   Button/
   Button/Button.tsx
   Button/Button.test.tsx
   Button/Button.styles.css
   Button/index.ts
5. Esc                              " Exit INSERT mode
6. Press =                          " Synchronize - creates everything!
7. Press q                          " Close MiniFiles
```

---

## Creating Files

### Method 1: Using MiniFiles (Recommended)

See MiniFiles section above - just press `=` to create!

### Method 2: Create File with Ex Command (Simple)

**Create file in current directory:**
```vim
:e newfile.js           " Edit (creates new file)
i                       " Enter INSERT mode
" Type content
:w                      " Save (actually creates the file)
```

**Create file in subdirectory:**
```vim
:e src/components/Header.jsx
" If directory exists, creates file
" If directory doesn't exist, shows error

" To create anyway:
:!mkdir -p src/components
:e src/components/Header.jsx
:w
```

**Create file with full path:**
```vim
:e ~/projects/myapp/src/utils/helpers.js
:w
```

### Method 2: Create File via Oil (Visual File Explorer)

Oil is the **recommended way** for file management in this config!

**Steps:**
```vim
1. Open Oil:
   -                    " Opens current directory

2. Navigate to parent if needed:
   -                    " Goes up one level

3. Create new file:
   i                    " Enter insert mode in Oil
   newfile.js           " Type filename
   Esc                  " Back to normal mode
   Enter                " Opens the new file

4. Oil auto-creates the file when you save:
   i                    " INSERT mode
   " Type content
   :w                   " Saves and creates file
```

**Create multiple files at once:**
```vim
1. -                    " Open Oil
2. i                    " Insert mode
3. file1.js             " Type first filename
   file2.js             " New line, second filename
   file3.js             " Third filename
4. Esc                  " Normal mode
5. :w                   " Oil creates all files!
```

### Method 3: Create from Telescope (Quick)

```vim
<leader>ff              " Find files
" Type non-existent filename
" Telescope will offer to create it
Ctrl-e                  " Create new file (if available)
```

## Creating Directories

### Method 1: Shell Command
```vim
:!mkdir -p path/to/new/directory
:e path/to/new/directory/file.js
:w
```

### Method 2: Oil (Recommended)

**Create single directory:**
```vim
1. -                    " Open Oil
2. i                    " Insert mode
3. newdir/              " Type dirname with trailing slash!
4. Esc
5. :w                   " Oil creates directory
```

**Create nested directories:**
```vim
1. -                    " Open Oil
2. i                    " Insert mode
3. src/components/ui/   " Deep nested path with trailing slash
4. Esc
5. :w                   " Creates all directories
```

**Create directory and file together:**
```vim
1. -                    " Open Oil
2. i                    " Insert mode
3. components/          " Create directory (with slash)
4. components/Header.jsx " Create file in that directory
5. Esc
6. :w                   " Creates both!
```

## Oil File Explorer - Complete Guide

Oil is your visual file manager. Think of it as a buffer that represents your file system.

### Opening Oil

| Keys | Action |
|------|--------|
| `-` | Open Oil in current directory |
| `:Oil` | Open Oil |
| `:Oil ~/projects` | Open Oil at specific path |

### Navigating in Oil

| Keys | Action |
|------|--------|
| `j` / `k` | Move down/up |
| `Enter` | Open file or enter directory |
| `-` | Go to parent directory |
| `g.` | Toggle hidden files (dotfiles) |
| `/` | Search for file |
| `gg` / `G` | Top/bottom of list |

### Creating Files/Directories

| Keys | Action |
|------|--------|
| `i` | Enter INSERT mode |
| Type filename | Create file entry |
| Type dirname/ | Create directory (trailing slash!) |
| `Esc` | Normal mode |
| `:w` | Save changes (creates files/dirs) |

### Deleting Files/Directories

| Keys | Action |
|------|--------|
| `dd` | Delete line (marks for deletion) |
| `:w` | Apply changes (actually deletes) |
| `u` | Undo (before saving) |

**Example:**
```vim
1. -               " Open Oil
2. j j j           " Navigate to file
3. dd              " Mark for deletion (turns red)
4. :w              " Actually deletes
5. q               " Close Oil (optional)
```

**Delete multiple files:**
```vim
1. -               " Open Oil
2. V               " Visual LINE mode
3. j j j           " Select 3 files
4. d               " Delete selection
5. :w              " Apply deletions
```

### Renaming Files

**Method 1: Edit in place**
```vim
1. -               " Open Oil
2. Find file
3. cw              " Change word (filename)
4. newname.js      " Type new name
5. Esc
6. :w              " Apply rename
```

**Method 2: Change extension**
```vim
1. -               " Open Oil
2. $               " End of filename
3. ct.             " Change till dot
4. newname
5. Esc
6. :w
```

**Method 3: Bulk rename**
```vim
1. -               " Open Oil
2. :%s/old/new/g   " Rename pattern across all files
3. :w              " Apply all renames
```

### Moving Files

**Move to different directory:**
```vim
1. -               " Open Oil
2. Find file: photo.jpg
3. cw              " Change filename
4. images/photo.jpg " Add directory path
5. Esc
6. :w              " Moves file!
```

**Move multiple files:**
```vim
1. -               " Open Oil
2. V               " Visual mode
3. Select files
4. : (command mode, shows :'<,'>)
5. s/^/target_dir\// " Add directory prefix
6. Esc
7. :w              " Moves all selected files
```

### Copying Files

Oil doesn't have direct copy, but you can duplicate:

**Duplicate a file:**
```vim
1. -               " Open Oil
2. yy              " Yank filename line
3. p               " Paste below
4. cw              " Change filename
5. copy.js         " New name
6. Esc
7. :w              " Creates copy
```

**Or use shell:**
```vim
:!cp file.js file_backup.js
:e .               " Reload directory
```

### Opening Files from Oil

| Keys | Action |
|------|--------|
| `Enter` | Open in current window |
| `Ctrl-v` | Open in vertical split |
| `Ctrl-x` | Open in horizontal split |
| `Ctrl-t` | Open in new tab |

### Oil Workflow Examples

**Example 1: Organize Project Files**
```vim
" Move all tests to test directory:
1. -                        " Open Oil
2. /test                    " Search for test files
3. V                        " Visual mode
4. j j j                    " Select all test files
5. :'<,'>s/^/tests\//       " Prefix with tests/
6. Esc
7. :w                       " Moves all to tests/ dir
```

**Example 2: Clean Up Directory**
```vim
" Delete all .log files:
1. -                        " Open Oil
2. /\.log$                  " Search for .log
3. dd                       " Delete first
4. n dd                     " Next and delete
5. (repeat or use macro)
6. :w                       " Apply deletions
```

**Example 3: Rename Pattern**
```vim
" Change all .jsx to .tsx:
1. -                        " Open Oil
2. :%s/\.jsx$/\.tsx/        " Replace extension
3. :w                       " Apply renames
```

## Traditional File Operations

### Using Ex Commands

**Create:**
```vim
:e filename                 " Create/edit file
:!mkdir dirname             " Create directory
```

**Delete:**
```vim
:!rm filename               " Delete file
:!rm -r dirname             " Delete directory
:call delete('filename')    " Vim-native delete
```

**Rename/Move:**
```vim
:!mv oldname newname        " Rename
:!mv file path/to/file      " Move
:saveas newname             " Save as (keeps both files)
```

**Copy:**
```vim
:!cp source dest            " Copy file
:!cp -r srcdir destdir      " Copy directory
```

## File Explorer (Netrw) - Fallback

If Oil isn't working, Neovim has built-in Netrw:

```vim
:Explore                    " Open in current window
:Sexplore                   " Horizontal split
:Vexplore                   " Vertical split
```

**In Netrw:**
- `Enter` - Open file/directory
- `%` - Create new file
- `d` - Create directory
- `D` - Delete
- `R` - Rename
- `-` - Go up directory
- `i` - Change view mode

## Quick File Creation Patterns

### Create File in Current Directory
```vim
:e %:h/newfile.js
" %:h expands to directory of current file
```

### Create File with Today's Date
```vim
:e note-<C-r>=strftime('%Y-%m-%d')<CR>.md
" Inserts date: note-2025-11-12.md
```

### Create Numbered Files
```vim
:!touch file{1..10}.js      " Creates file1.js through file10.js
```

### Create from Template
```vim
:!cp template.js newfile.js
:e newfile.js
```

## Practical Workflows

### Workflow 1: New Component

**Create React component with all files:**
```vim
1. -                           " Open Oil
2. i                           " Insert mode
3. Type:
   components/Button/
   components/Button/Button.tsx
   components/Button/Button.test.tsx
   components/Button/Button.styles.css
   components/Button/index.ts
4. Esc
5. :w                          " Creates everything!
```

### Workflow 2: Reorganize Codebase

**Move all components to new structure:**
```vim
1. -                           " Open Oil in src/
2. V                           " Visual mode
3. Select all component files
4. :'<,'>s/^/components\//     " Prefix with components/
5. Esc
6. :w                          " Moves all files
7. Fix imports with LSP:
   - Find errors: <leader>D
   - Fix imports: <leader>vca
```

### Workflow 3: Clean Up Old Files

**Delete all .bak files:**
```vim
1. -                           " Open Oil
2. :%g/\.bak$/d                " Delete lines matching .bak
3. :w                          " Actually deletes files
```

### Workflow 4: Batch Rename

**Rename test files:**
```vim
1. -                           " Open Oil
2. :%s/\.spec\.js$/\.test.js/  " spec -> test
3. :w                          " Apply renames
```

## Tips & Tricks

### Preview Before Save

Oil doesn't actually modify files until you `:w`. Review your changes before applying!

```vim
1. -               " Open Oil
2. Make changes
3. Review (marked in different colors)
4. :w              " Apply
   OR
4. :q!             " Cancel all changes
```

### Undo in Oil

Before saving:
```vim
u                  " Undo last change in Oil
Ctrl-r             " Redo
```

After saving:
```vim
:!git restore file " If in git repo
:earlier 1m        " Restore buffer state from 1 min ago
```

### Create Nested Structure Fast

```vim
:!mkdir -p src/components/ui/{Button,Input,Modal}
" Creates:
" src/components/ui/Button/
" src/components/ui/Input/
" src/components/ui/Modal/
```

### Open File in Split from Oil

```vim
1. -               " Open Oil
2. Navigate to file
3. Ctrl-v          " Opens in vertical split
   OR
3. Ctrl-x          " Opens in horizontal split
```

### Toggle Hidden Files

```vim
1. -               " Open Oil
2. g.              " Show/hide dotfiles
```

## Troubleshooting

### "Oil won't create directory"

Make sure to add trailing slash:
```vim
dirname/           " ← Slash tells Oil it's a directory
```

### "Oil shows error when creating file"

Parent directory may not exist:
```vim
:!mkdir -p path/to/parent
-                  " Reopen Oil
```

### "Can't delete file in Oil"

Check file permissions:
```vim
:!ls -la           " Check permissions
:!chmod +w file    " Add write permission
```

### "Oil changes not saving"

Remember to `:w` in Oil buffer to apply changes!

## Quick Reference

**Create File:**
```vim
-                  " Open Oil
i                  " Insert
filename.js        " Type name
Esc :w             " Save
```

**Create Directory:**
```vim
-                  " Open Oil
i                  " Insert
dirname/           " Trailing slash!
Esc :w             " Save
```

**Delete:**
```vim
-                  " Open Oil
dd                 " Delete line
:w                 " Apply
```

**Rename:**
```vim
-                  " Open Oil
cw                 " Change word
newname            " Type new name
Esc :w             " Apply
```

**Move:**
```vim
-                  " Open Oil
cw                 " Change word
path/file          " New path
Esc :w             " Apply
```

---

**Pro Tip:** Oil is like a regular buffer - you can use all your normal Vim commands (`dd`, `yy`, `p`, search, etc.) on your file system!

**Remember:** Changes in Oil are **not applied** until you `:w`. This gives you a preview and chance to undo!

**Next:** [Search & Replace Workflows](search-replace.md)
