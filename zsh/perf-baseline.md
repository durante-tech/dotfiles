# Shell Startup Baseline

Captured: 2026-05-27. Reproduce with:

```bash
hyperfine --warmup 3 --runs 10 'zsh -i -c exit'
ZSH_PROFILE=1 zsh -i -c exit
```

## Baseline (2026-05-27)

| Metric | Value |
|--------|-------|
| Wall-clock (hyperfine mean) | _captured below_ |
| Top zprof culprit | `_mise_hook` (~19ms, 41%) |
| 2nd culprit | `compinit` (~13ms, 28%) |
| 3rd culprit | `_zsh_highlight_load_highlighters` (~5ms, 11%) |

## Wall-clock output

```
```

## Top zprof entries

```
num  calls                time                       self            name
-----------------------------------------------------------------------------------
 1)    1          19.32    19.32   51.47%     19.32    19.32   51.47%  _mise_hook
 2)    1           9.60     9.60   25.58%      9.60     9.60   25.58%  compinit
 3)    1           4.18     4.18   11.13%      4.14     4.14   11.02%  _zsh_highlight_load_highlighters
 4)    1           1.77     1.77    4.73%      1.77     1.77    4.73%  (anon) [/usr/share/zsh/5.9/functions/add-zle-hook-widget:28]
 5)    1           0.95     0.95    2.54%      0.95     0.95    2.52%  _zsh_highlight__function_callable_p
 6)   11           0.61     0.06    1.62%      0.61     0.06    1.62%  add-zsh-hook
 7)    3           2.15     0.72    5.73%      0.38     0.13    1.00%  add-zle-hook-widget
 8)    1           0.35     0.35    0.94%      0.35     0.35    0.94%  __fzf_git_init
 9)    3           0.27     0.09    0.72%      0.27     0.09    0.72%  is-at-least
10)    1           0.10     0.10    0.27%      0.10     0.10    0.27%  (anon) [/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh:460]
11)    1           0.05     0.05    0.13%      0.05     0.05    0.13%  compdef
12)    1           0.01     0.01    0.02%      0.01     0.01    0.02%  _zsh_highlight__is_function_p
13)    1           0.00     0.00    0.00%      0.00     0.00    0.00%  _zsh_highlight_bind_widgets

```
