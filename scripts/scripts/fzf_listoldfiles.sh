#!/bin/bash

# Script to list recent files and open nvim using fzf
# set to an alias nlof in .zshrc

list_oldfiles() {
    # Get the oldfiles list from Neovim.
    #
    # Read line-by-line rather than `arr=($(...))`. The old form split on IFS,
    # so any recent file whose path contained a space was shredded into
    # fragments that then failed the -f test below and vanished from the list.
    # `mapfile` would be the idiomatic fix but this runs under /bin/bash 3.2 on
    # macOS, which does not have it.
    local oldfiles=() line
    while IFS= read -r line; do
        [[ -n "$line" ]] && oldfiles+=("$line")
    done < <(nvim -u NONE --headless +'lua io.write(table.concat(vim.v.oldfiles, "\n") .. "\n")' +qa)
    # Filter invalid paths or files not found
    local valid_files=()
    for file in "${oldfiles[@]}"; do
        if [[ -f "$file" ]]; then
            valid_files+=("$file")
        fi
    done
    # Use fzf to select from valid files. Same line-wise read as above — with
    # --multi, a selected path containing a space was previously split across
    # several array slots and nvim opened phantom files.
    local files=() sel
    while IFS= read -r sel; do
        [[ -n "$sel" ]] && files+=("$sel")
    done < <(printf "%s\n" "${valid_files[@]}" | \
        grep -v '\[.*' | \
        fzf --multi \
        --preview 'bat -n --color=always --line-range=:500 {} 2>/dev/null || echo "Error previewing file"' \
        --height=70% \
        --layout=default)

    # Open selected files in Neovim
    if [[ ${#files[@]} -gt 0 ]]; then
        # make neovim recognize path of the file opened
        local first_dir=$(dirname "${files[0]}")
        cd "$first_dir" || { echo "Failed to cd to $first_dir"; return 1; }
        nvim "${files[@]}"
    fi
}

# Call the function
list_oldfiles "$@"
