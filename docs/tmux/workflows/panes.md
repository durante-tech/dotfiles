# Pane Management Workflows

Master tmux panes for efficient multi-view terminal work.

## What Are Panes?

**Panes** are splits within a tmux window. Think of them as:
- Multiple terminal views in one window
- Like split-screen in your terminal
- Perfect for seeing code + tests, or editor + server logs simultaneously

**Hierarchy:**
```
Session → Windows → Panes
```

## Creating Panes (Splitting)

### Your Custom Keybindings

**Split vertically (side by side):**
```
C-b |                   # Creates pane to the right
```

**Split horizontally (top and bottom):**
```
C-b -                   # Creates pane below
```

**Why these keys?**
- `|` looks like a vertical line (vertical split)
- `-` looks like a horizontal line (horizontal split)
- Intuitive and visual!

### Split Patterns

**Two panes side by side:**
```
+--------+--------+
|        |        |
|   A    |   B    |
|        |        |
+--------+--------+

C-b |
```

**Three panes:**
```
+--------+--------+
|        |        |
|   A    |   B    |
|        +--------+
|        |   C    |
+--------+--------+

C-b |                   # Split vertical
C-l                     # Move to right pane
C-b -                   # Split horizontal
```

**Four panes (quad):**
```
+--------+--------+
|   A    |   B    |
+--------+--------+
|   C    |   D    |
+--------+--------+

C-b |                   # Split vertical
C-b -                   # Split horizontal
C-h                     # Move left
C-b -                   # Split horizontal
```

## Navigating Between Panes

### Your Vim-Style Navigation

**Move between panes:**
```
C-h                     # Move left
C-j                     # Move down
C-k                     # Move up
C-l                     # Move right
```

**Why this is awesome:**
- Same keys work in **Neovim** and **tmux**!
- No mental context switch
- Thanks to vim-tmux-navigator plugin

### Alternative Navigation

**Show pane numbers:**
```
C-b q                   # Shows numbers briefly
C-b q 2                 # Jump to pane 2 (while numbers showing)
```

**Cycle through panes:**
```
C-b o                   # Next pane (clockwise)
C-b ;                   # Last pane (toggle)
```

## Resizing Panes

### Your Custom Keybindings

**Resize panes (vim-style):**
```
C-b h                   # Resize left (shrink right)
C-b j                   # Resize down (shrink top)
C-b k                   # Resize up (shrink bottom)
C-b l                   # Resize right (shrink left)
```

**How it works:**
- Each press resizes by 5 cells
- Repeatable (the `-r` flag in config)
- Hold `C-b` and tap `h` multiple times quickly

**Example:**
```
+-------+---+
|       |   |     C-b llll   +-----+-----+
|   A   | B |   ---------->  |  A  |  B  |
|       |   |                +-----+-----+
+-------+---+
```

### Even Panes

**Make all panes equal size:**
```
C-b M-1                 # Even horizontal
C-b M-2                 # Even vertical
C-b M-5                 # Tiled layout
```

Or use built-in layout cycling:
```
C-b Space               # Cycle through layouts
# Keep pressing Space to see different arrangements
```

## Zooming Panes

**Maximize pane (zoom):**
```
C-b m                   # Toggle maximize
# Or
C-b z                   # Also toggles maximize
```

**Use case:**
- Focus on one pane temporarily
- Present code on video call
- Read logs full-screen
- Toggle back when done

**Visual indicator:**
- Status bar shows " zoom " when zoomed
- Pane takes full window

## Managing Panes

### Closing Panes

**Close current pane:**
```
exit                    # Type in shell
# Or
C-b x                   # Prompts for confirmation (y/n)
# Or
C-d                     # If shell allows
```

### Moving Panes

**Swap panes:**
```
C-b {                   # Swap with previous pane
C-b }                   # Swap with next pane
```

**Rotate panes:**
```
C-b C-o                 # Rotate panes clockwise
C-b M-o                 # Rotate panes counter-clockwise
```

### Breaking Panes

**Move pane to new window:**
```
C-b !                   # Break pane out to new window
```

**Join pane from another window:**
```
C-b :join-pane -s :2    # Bring pane from window 2
C-b :join-pane -h -s :2.1  # Join pane horizontally
```

### Marking Panes

**Mark a pane:**
```
C-b m                   # Mark current pane
```

**Swap with marked:**
```
C-b M-o                 # Swap with marked pane
```

## Pane Layouts

### Built-in Layouts

**Apply layout:**
```
C-b M-1                 # even-horizontal
C-b M-2                 # even-vertical
C-b M-3                 # main-horizontal
C-b M-4                 # main-vertical
C-b M-5                 # tiled
```

**Cycle layouts:**
```
C-b Space               # Next layout
```

**Visual examples:**

**even-horizontal:**
```
+-----+-----+-----+
|  A  |  B  |  C  |
+-----+-----+-----+
```

**even-vertical:**
```
+---------------+
|       A       |
+---------------+
|       B       |
+---------------+
|       C       |
+---------------+
```

**main-horizontal:**
```
+---------------+
|       A       |
+-------+-------+
|   B   |   C   |
+-------+-------+
```

**tiled:**
```
+-------+-------+
|   A   |   B   |
+-------+-------+
|   C   |   D   |
+-------+-------+
```

## Common Pane Workflows

### Workflow 1: Code + Tests

**Setup:**
```
+------------------+----------+
|                  |          |
|      nvim        |  Tests   |
|   (editing)      | (watch)  |
|                  |          |
+------------------+----------+

# Create:
nvim                    # Start editing
C-b |                   # Split
npm test -- --watch     # Run tests
C-h                     # Back to editor
```

**Benefit:** See test results as you code!

### Workflow 2: Code + Server + Logs

**Setup:**
```
+------------------+----------+
|                  |  Server  |
|      nvim        |  (dev)   |
|                  +----------+
|                  |   Logs   |
+------------------+----------+

# Create:
nvim
C-b |                   # Split
npm run dev             # Start server
C-b -                   # Split again
tail -f app.log         # Watch logs
C-h                     # Back to editor
```

### Workflow 3: Edit + Git + Terminal

**Setup:**
```
+------------------+----------+
|                  |   Git    |
|      nvim        |  status  |
|                  +----------+
|                  | Terminal |
+------------------+----------+

# Create:
nvim
C-b |
git status
C-b -
# Ready for commands
```

### Workflow 4: Multi-file Editing

**Setup:**
```
+----------+----------+----------+
|  file1   |  file2   |  file3   |
|   .js    |   .css   |  .test   |
+----------+----------+----------+

# Create:
nvim file1.js
C-b |
nvim file2.css
C-b |
nvim file3.test.js

# Navigate:
C-h/l                   # Switch between files
```

**Or better:** Use Neovim splits instead!

### Workflow 5: Documentation + Implementation

**Setup:**
```
+----------+------------------+
|   Docs   |                  |
|  (less)  |       nvim       |
|          |   (implement)    |
+----------+------------------+

# Create:
less API_DOCS.md
C-b |
nvim implementation.js
```

### Workflow 6: Database + Code

**Setup:**
```
+------------------+----------+
|                  |  psql    |
|      nvim        | (query)  |
|                  |          |
+------------------+----------+

# Create:
nvim
C-b |
psql mydb
```

**Run queries while coding!**

### Workflow 7: Comparison (Diff)

**Setup:**
```
+----------+----------+
| before   |  after   |
|          |          |
+----------+----------+

# Create:
cat before.txt
C-b |
cat after.txt

# Or with nvim:
nvim -d before.txt after.txt
# Better: use vim's built-in diff!
```

## Advanced Pane Techniques

### Synchronized Panes

**Type in all panes simultaneously:**
```
C-b :setw synchronize-panes on

# Now typing appears in ALL panes!
# Great for:
# - Running same command on multiple servers
# - Synchronized demo/presentation
# - Batch operations

C-b :setw synchronize-panes off  # Disable
```

### Pane Titles

**Set pane title:**
```
C-b :select-pane -T "My Pane Title"
```

**Show pane titles:**
```
C-b :set -g pane-border-status top
```

### Pane Commands

**Run command in pane without switching:**
```
C-b :send-keys -t 2 "ls -la" Enter
# Runs "ls -la" in pane 2
```

**Useful for automation!**

### Pane Pipe

**Pipe pane output to file:**
```
C-b :pipe-pane -o "cat >> ~/pane-output.log"
# All output saved to file

C-b :pipe-pane          # Stop piping
```

**Great for capturing logs!**

## Pane Best Practices

### When to Split

**Good reasons:**
- Code + tests (see results immediately)
- Editor + server logs (monitor while coding)
- Multiple related tasks (git + editing)
- Comparison (before/after)

**Bad reasons:**
- Too many splits (>4 gets crowded)
- Unrelated tasks (use windows instead)
- When zooming is needed constantly

### Optimal Pane Count

**Recommended:**
- **2 panes:** Most common (code + auxiliary)
- **3 panes:** Good for complex tasks
- **4 panes:** Maximum before it gets cramped

**Avoid:**
- 5+ panes unless you have huge monitor
- Tiny panes that are hard to read

### Pane vs Window

**Use panes when:**
- Tasks are related
- Need to see both simultaneously
- Switching frequently

**Use windows when:**
- Tasks are separate (server, tests, docs)
- Don't need to see simultaneously
- Clear mental separation

### Layout Tips

**Vertical splits for:**
- Code editors (wide screens benefit from vertical)
- Side-by-side comparisons
- Editor + auxiliary (terminal, logs)

**Horizontal splits for:**
- Terminal + logs (stack vertically)
- REPL + output
- Command + results

## Mouse Support

**Your config has mouse enabled!**

**What you can do:**
- **Click pane** - Switch to it
- **Drag border** - Resize panes
- **Scroll wheel** - Scroll in pane (enters copy mode)
- **Select text** - Copy with mouse

**Toggle mouse mode:**
```
C-b :set -g mouse off   # Disable
C-b :set -g mouse on    # Enable
```

## Troubleshooting

**"Pane is too small"**
```
C-b hjkl                # Resize
C-b m                   # Zoom temporarily
C-b Space               # Try different layout
```

**"Can't switch to pane"**
```
C-b q                   # Show pane numbers
# Are all panes visible?
# Try: C-b z to unzoom
```

**"Lost in panes"**
```
C-b z                   # Zoom current pane
C-b q                   # Show numbers
C-b :kill-pane -a       # Kill all other panes (careful!)
```

**"Pane navigation not working"**
```
# vim-tmux-navigator issue?
# Check if you're in vim/nvim
# C-h/j/k/l should work in both

# If broken:
C-b :source-file ~/.config/tmux/tmux.conf
```

**"Want to start over"**
```
C-b :kill-window        # Kill whole window (all panes)
C-b c                   # New clean window
```

## Keyboard Shortcuts Summary

| Keys | Action |
|------|--------|
| **Creating** | |
| `C-b \|` | Split vertical |
| `C-b -` | Split horizontal |
| **Navigating** | |
| `C-h/j/k/l` | Move between panes |
| `C-b q` | Show pane numbers |
| `C-b o` | Next pane |
| `C-b ;` | Last pane |
| **Resizing** | |
| `C-b h/j/k/l` | Resize panes |
| `C-b Space` | Cycle layouts |
| `C-b M-1/2/3/4/5` | Apply layout |
| **Managing** | |
| `C-b m` | Maximize/zoom |
| `C-b x` | Close pane |
| `C-b !` | Break to new window |
| `C-b {/}` | Swap panes |

---

**Pro Tip:** Master `C-h/j/k/l` for navigation - it works in tmux AND Neovim. One set of keys for all your pane/window navigation!

**Next:** [Copy Mode](copy-mode.md) - Vim-style scrolling and copying
