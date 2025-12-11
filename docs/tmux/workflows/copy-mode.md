# Copy Mode Workflows

Master tmux copy mode for vim-style scrolling, searching, and copying.

## What is Copy Mode?

**Copy mode** is tmux's way of:
- Scrolling back through terminal history
- Searching through output
- Copying text to clipboard
- Navigating like vim in your terminal

**Think of it as:** Vim for your terminal history!

**Your config uses vi keybindings**, so if you know vim, you already know copy mode.

## Entering Copy Mode

### Your Custom Keybinding

**Enter copy mode:**
```
C-b v                   # "v" for vim/visual
```

**Or standard binding:**
```
C-b [                   # Traditional tmux binding
```

**Or with mouse:**
```
Scroll wheel up         # Enters copy mode automatically
```

### Visual Indicator

**When in copy mode, you'll see:**
```
[0/0]                   # Top right of pane
# First number: current position
# Second number: total lines
```

**Status also shows:**
- Line numbers
- Current mode (copy mode)
- Selection highlighting (if selecting)

## Exiting Copy Mode

**Three ways to exit:**
```
q                       # Quit copy mode
C-c                     # Cancel (like vim)
Enter (if no selection) # Exit without copying
```

**Auto-exit:**
- Pressing `y` (yank) automatically exits after copying
- Pressing `Enter` after selection copies and exits

## Navigation (Vi Keys)

### Basic Movement

**Character movement:**
```
h                       # Left
j                       # Down
k                       # Up
l                       # Right
```

**Word movement:**
```
w                       # Next word start
W                       # Next WORD start (space-separated)
b                       # Previous word start
B                       # Previous WORD start
e                       # Next word end
E                       # Next WORD end
```

**Line movement:**
```
0                       # Start of line
^                       # First non-blank character
$                       # End of line
```

### Screen Movement

**Page up/down:**
```
C-u                     # Half page up
C-d                     # Half page down
C-b                     # Full page up (Ctrl+b, conflicts with prefix!)
C-f                     # Full page down
```

**Note about C-b:**
- In copy mode, `C-b` means page up (not tmux prefix)
- Outside copy mode, `C-b` is the tmux prefix

**Screen positioning:**
```
H                       # Top of screen (High)
M                       # Middle of screen
L                       # Bottom of screen (Low)
```

### Buffer Movement

**Jump to position:**
```
gg                      # Top of history buffer
G                       # Bottom of history buffer (most recent)
5G                      # Go to line 5
50%                     # Go to 50% of buffer
```

**Jump by section:**
```
{                       # Previous paragraph
}                       # Next paragraph
(                       # Previous sentence
)                       # Next sentence
```

## Searching

### Basic Search

**Search forward:**
```
/pattern                # Search forward
Enter                   # Execute search
```

**Search backward:**
```
?pattern                # Search backward
Enter                   # Execute search
```

**Navigate matches:**
```
n                       # Next match (same direction)
N                       # Previous match (opposite direction)
```

### Search Tips

**Case sensitivity:**
```
/Test                   # Matches "Test", not "test"
/test                   # Matches "test", not "Test"
```

**Partial matches:**
```
/err                    # Finds "error", "Error", "stderr"
```

**Search for exact word:**
```
/\<error\>              # Only matches "error", not "errors"
```

### Common Search Patterns

**Find error messages:**
```
/[Ee]rror               # Case insensitive error
/ERROR                  # All caps errors
/err\|warn              # Errors OR warnings
```

**Find file paths:**
```
//home                  # Paths starting with /home
/\.js                   # JavaScript files
```

**Find numbers:**
```
/[0-9]\+                # Any number
/port.*[0-9]\+          # "port 3000", "port 8080"
```

**Find timestamps:**
```
/[0-9]\{2\}:[0-9]\{2\}  # Matches HH:MM format
```

## Selecting Text

### Visual Mode (v)

**Start selection:**
```
v                       # Character-wise selection (like vim)
```

**Extend selection:**
- Use any movement keys: `h/j/k/l`, `w/b`, `0/$`, etc.
- Selection highlights as you move

**Copy selection:**
```
y                       # Yank (copy) and exit
Enter                   # Copy and exit (alternative)
```

**Cancel selection:**
```
Escape                  # Cancel without copying
q                       # Exit copy mode
```

### Line Visual Mode (V)

**Line selection:**
```
V                       # Select entire lines (like vim)
```

**Extend selection:**
- `j/k` to select more/fewer lines
- Always selects complete lines

**Copy:**
```
y                       # Yank lines and exit
```

### Block Visual Mode (C-v)

**Block selection:**
```
C-v                     # Select rectangular block (like vim)
```

**Use case:**
- Copy columns from output
- Select formatted data
- ASCII art or tables

**Example - copy second column:**
```
# From output like:
# Name    Age    City
# Alice   30     NYC
# Bob     25     LA

# Navigate to "Age", press C-v
# Move down with j to select column
# Press y to copy
```

## Copying Text

### Copy to Tmux Buffer

**What is tmux buffer?**
- Internal clipboard managed by tmux
- Separate from system clipboard
- Persists in tmux session
- Can store multiple buffers

**Copy to buffer:**
```
# In copy mode:
v                       # Start selection
# Move to extend selection
y                       # Copy to tmux buffer (and exit)
```

### Paste from Tmux Buffer

**Paste what you copied:**
```
C-b ]                   # Paste from tmux buffer
# Works outside copy mode, in normal pane
```

**Where it pastes:**
- Current cursor position in terminal
- Types the text as if you typed it
- Works in any program (shell, vim, etc.)

### System Clipboard Integration

**Your config may have system clipboard support.**

**Check if enabled:**
- When you copy in copy mode, can you paste in other apps?
- If yes, clipboard integration is working!

**Manual clipboard copy (macOS):**
```
# If clipboard not integrated:
C-b ]                   # Paste from tmux buffer
# Then manually select and Cmd+C

# Or pipe to pbcopy:
tmux show-buffer | pbcopy
```

**Manual clipboard paste:**
```
# macOS:
pbpaste | tmux load-buffer -
C-b ]

# Linux:
xclip -o | tmux load-buffer -
C-b ]
```

## Buffer Management

### Multiple Buffers

**Tmux can store multiple copied texts:**
```
# Each time you copy (y), it's stored in a new buffer
# Buffers are numbered: 0 (most recent), 1, 2, 3, ...
```

**List buffers:**
```
C-b =                   # Shows buffer list
# Or
C-b :list-buffers
```

**Choose buffer to paste:**
```
C-b =                   # Interactive buffer list
# Navigate with j/k
# Press Enter to paste selected buffer
```

**Paste specific buffer:**
```
C-b :paste-buffer -b 2  # Paste buffer 2
```

**Delete buffer:**
```
C-b :delete-buffer -b 0  # Delete most recent buffer
```

**Save buffer to file:**
```
C-b :save-buffer ~/saved.txt
```

**Load file into buffer:**
```
C-b :load-buffer ~/file.txt
C-b ]                   # Paste it
```

## Common Copy Mode Workflows

### Workflow 1: Copy Error Message

**Scenario:** Long error in terminal, need to copy it

```
1. C-b v                # Enter copy mode
2. /error               # Search for "error"
3. n (if needed)        # Find the specific error
4. v                    # Start selection at error
5. }                    # Extend to end of paragraph (whole error)
6. y                    # Copy and exit

7. Paste in browser/Slack/issue tracker
   - If clipboard integrated: Cmd+V
   - If not: C-b ] (in another pane/terminal)
```

### Workflow 2: Copy Command Output

**Scenario:** Ran command, want to save output

```
1. # Run command (e.g., npm test)
2. C-b v                # Enter copy mode
3. gg                   # Top of output
4. V                    # Line visual mode
5. G                    # To bottom
6. y                    # Copy all output

7. C-b ]                # Paste in editor/file
```

### Workflow 3: Copy Specific Lines

**Scenario:** Extract lines 50-60 from logs

```
1. C-b v                # Enter copy mode
2. gg                   # Top of buffer
3. 50G                  # Jump to line 50
4. V                    # Line visual mode
5. 10j                  # Select 10 lines down
6. y                    # Copy

7. C-b ]                # Paste
```

### Workflow 4: Copy File Path

**Scenario:** Error shows file path, need to open it

```
1. C-b v                # Enter copy mode
2. /\/home              # Search for path starting with /
3. v                    # Start selection
4. e                    # Extend to end of word
5. e (repeat)           # Keep extending until full path
   # Or use $            (if path is at end of line)
6. y                    # Copy

7. Esc (exit program showing error)
8. nvim                 # Start nvim
9. C-b ]                # Paste path
10. Enter               # Open file
```

**Or use this trick:**
```
# After copying path:
nvim $(tmux show-buffer)
# Opens file directly!
```

### Workflow 5: Search and Copy All Matches

**Scenario:** Copy all lines containing "TODO"

```
1. C-b v                # Enter copy mode
2. /TODO                # Search for TODO
3. V                    # Line visual mode
4. n                    # Jump to next TODO
5. V (on next match)    # Select that line too
6. (Repeat for all matches)
7. y                    # Copy all selected lines
```

**Better approach - use grep:**
```
tmux capture-pane -p | grep TODO
# Captures pane and filters with grep
```

### Workflow 6: Copy Command for Repeat

**Scenario:** Someone showed you command, want to run it

```
1. C-b v                # Enter copy mode
2. ?$ (or ?prompt)      # Search backward for prompt
3. 0                    # Start of line
4. v                    # Start selection
5. $                    # End of line
6. y                    # Copy command

7. C-b ]                # Paste and run
8. Enter
```

### Workflow 7: Copy Table Column

**Scenario:** Command output is table, need second column

```
# Example output:
# NAME    PID    MEM%
# node    1234   45.2
# ruby    5678   23.1

1. C-b v                # Enter copy mode
2. Navigate to "PID"
3. C-v                  # Block visual mode
4. 2j                   # Select column down
5. e                    # Extend to end of numbers
6. y                    # Copy

# Pastes:
# 1234
# 5678
```

### Workflow 8: Save Terminal Session

**Scenario:** Want to save entire terminal output

```
1. C-b v                # Enter copy mode
2. gg                   # Top of history
3. VG                   # Select everything
4. y                    # Copy

5. C-b :save-buffer ~/session-$(date +%Y%m%d).txt
# Saves to file with date
```

**Or directly capture:**
```
C-b :capture-pane -S -1000  # Capture last 1000 lines
C-b :save-buffer ~/output.txt
```

## Advanced Copy Mode Techniques

### Jump to Marks

**Set mark:**
```
m                       # Set mark at current position
```

**Jump to mark:**
```
'                       # Jump back to mark
```

**Use case:**
- Mark starting point
- Scroll around to find something
- Jump back to mark to start selection

### Rectangle Copy

**Copy ASCII art or formatted text:**
```
┌─────┬─────┐
│  A  │  B  │
├─────┼─────┤
│  C  │  D  │
└─────┴─────┘

# Want to copy just the A box:
C-v (on top-left corner)
# Move to bottom-right of A box
y (copies rectangle)
```

### Incremental Search

**Search as you type:**
```
/                       # Start search
# Type partial: er
# Shows matches as you type
# Complete: error
Enter
```

**Navigate during search:**
```
# While in search prompt:
C-n                     # Next match (while typing)
C-p                     # Previous match (while typing)
```

### Copy with Mouse

**Your config has mouse mode enabled!**

**Select with mouse:**
1. Enter copy mode: `C-b v`
2. Click and drag to select
3. Release mouse
4. Press `y` to copy

**Or direct mouse copy:**
1. Hold `Shift` (bypasses tmux)
2. Click and drag
3. Release
4. Text copied to system clipboard!

**Shift key trick:**
- `Shift + select` = system clipboard (bypasses tmux)
- Regular select in copy mode = tmux buffer

### Copy Pane Content to File

**Entire visible pane:**
```
C-b :capture-pane
C-b :save-buffer ~/pane-output.txt
```

**With history:**
```
C-b :capture-pane -S -3000  # Last 3000 lines
C-b :save-buffer ~/full-output.txt
```

**Specific range:**
```
C-b :capture-pane -S -100 -E -50  # Lines 100-50 from end
C-b :save-buffer ~/range.txt
```

**Direct to file:**
```
C-b :pipe-pane -o "cat >> ~/live-log.txt"
# All output from pane continuously saved!
C-b :pipe-pane  # Stop logging
```

### Search and Replace (via external tool)

**Copy all output, modify, paste back:**
```
1. C-b v                # Copy mode
2. gg                   # Top
3. VG                   # Select all
4. y                    # Copy

5. C-b :save-buffer ~/temp.txt
6. sed 's/old/new/g' ~/temp.txt > ~/temp2.txt
7. cat ~/temp2.txt
# Modified output shown
```

## Keyboard Shortcuts Summary

| Keys | Action |
|------|--------|
| **Entering/Exiting** | |
| `C-b v` | Enter copy mode |
| `C-b [` | Enter copy mode (standard) |
| `q` | Exit copy mode |
| `C-c` | Exit copy mode |
| **Navigation** | |
| `h/j/k/l` | Move cursor |
| `w/b/e` | Word movement |
| `0/$` | Start/end of line |
| `gg/G` | Top/bottom of buffer |
| `C-u/C-d` | Half page up/down |
| `C-f/C-b` | Full page up/down |
| `{/}` | Paragraph movement |
| **Searching** | |
| `/` | Search forward |
| `?` | Search backward |
| `n` | Next match |
| `N` | Previous match |
| **Selecting** | |
| `v` | Visual (character) |
| `V` | Visual line |
| `C-v` | Visual block |
| **Copying** | |
| `y` | Yank (copy) |
| `Enter` | Copy and exit |
| `Escape` | Cancel selection |
| **Pasting** | |
| `C-b ]` | Paste buffer |
| `C-b =` | Choose buffer |

## Configuration Tips

### Change Copy Mode Key

**If you prefer a different key:**
```
# In tmux.conf:
bind-key -T prefix y copy-mode    # C-b y instead of C-b v
```

### Use Emacs Keys Instead

**Switch from vi to emacs mode:**
```
# In tmux.conf:
set-window-option -g mode-keys emacs
```

**Emacs navigation:**
- `C-p/C-n` - Up/down
- `C-f/C-b` - Forward/back
- `M-f/M-b` - Word forward/back
- `C-a/C-e` - Start/end of line

### Increase History Size

**More scrollback:**
```
# In tmux.conf:
set-option -g history-limit 10000   # Default is 2000
```

**Then reload:**
```
C-b r
```

### Clipboard Integration (macOS)

**Enable system clipboard:**
```
# In tmux.conf:
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "pbcopy"
```

**For Linux (X11):**
```
# In tmux.conf:
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"
```

**For Linux (Wayland):**
```
# In tmux.conf:
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "wl-copy"
```

## Troubleshooting

**"Can't scroll in terminal"**
```
# Are you in copy mode? If not:
C-b v                   # Enter copy mode
# Now you can scroll with j/k or C-u/C-d
```

**"Scrolling enters copy mode automatically"**
```
# Mouse mode is on (good!)
# To exit:
q
```

**"Copied text not in system clipboard"**
```
# Check if clipboard integration is configured
# See "Clipboard Integration" above

# Workaround:
C-b ]                   # Paste in tmux
# Then use mouse to select and Cmd+C
```

**"Lost my place in copy mode"**
```
m                       # Set mark
# Scroll around
'                       # Jump back to mark
```

**"Selection disappeared"**
```
# Did you press Escape or q?
# Start over:
v                       # Start selection
```

**"Can't find text I'm looking for"**
```
# History might be limited
# Check history-limit:
C-b :display-message -p "#{history_limit}"

# Increase in tmux.conf:
set-option -g history-limit 10000
```

**"Search not working"**
```
# Are you in copy mode?
C-b v                   # Enter first
/pattern                # Then search
```

**"Copy mode exits immediately"**
```
# This happens if you press Enter without selection
# To stay in copy mode after Enter:
# Use y to yank instead
```

**"Wrong text copied"**
```
# Check what's in buffer:
C-b :show-buffer

# Or list all buffers:
C-b =
```

**"Can't paste in vim/nvim"**
```
# In vim, use put command:
:put
# Or
"+ p (system clipboard)
"* p (selection clipboard)

# Or use tmux paste:
C-b ]
```

## Best Practices

### 1. Learn Vi Keys

**If you know vim:**
- Copy mode is second nature
- Same muscle memory

**If you don't know vim:**
- Learn basic navigation: `h/j/k/l`, `w/b`, `0/$`, `gg/G`
- Practice in copy mode and vim simultaneously
- Both benefit from same knowledge

### 2. Use Search Efficiently

**Instead of scrolling:**
```
# Slow:
C-b v
# Scroll up manually...

# Fast:
C-b v
?error                  # Jump directly to "error"
```

### 3. Mark Your Spot

**Before scrolling:**
```
C-b v                   # Enter copy mode
m                       # Mark position
# Scroll around
'                       # Jump back
```

### 4. Visual Line for Full Lines

**Copying complete lines:**
```
# Instead of:
v 0 $ y                 # Select from start to end

# Do:
V y                     # Line visual mode
```

### 5. Use Mouse When Convenient

**For quick selections:**
- Mouse is faster than keyboard for arbitrary positions
- Hold Shift for system clipboard
- Use keyboard for precise, repeatable operations

### 6. Buffer Management

**Don't overflow buffers:**
```
C-b =                   # Review buffers occasionally
# Delete old ones if needed
```

**Important text → file:**
```
C-b :save-buffer ~/important.txt
# Don't trust buffer for critical data
```

### 7. Capture Pane for Full Output

**For large output:**
```
# Instead of copy mode + select all:
C-b :capture-pane -S -
C-b :save-buffer ~/output.txt

# Faster and captures everything!
```

---

**Pro Tip:** Think of copy mode as "vim for terminal history". If you're comfortable with vim motions, copy mode becomes incredibly powerful for navigating, searching, and copying terminal output!

**Next:** [Keybindings Reference](../keybindings.md) - Complete tmux keyboard shortcut guide
