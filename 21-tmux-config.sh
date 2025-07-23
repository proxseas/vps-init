#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 21-tmux-config.sh - Tmux configuration setup (NO SUDO)
# =============================================================================
# This script configures tmux for the current user.
# USAGE: ./21-tmux-config.sh (as regular user)
# =============================================================================

# Source utilities
source "$(dirname "$0")/utils.sh"

# Check if running with sudo (should NOT be)
check_not_root

# ---- Tmux Configuration ----
print_section "Tmux Configuration"

TMUX_CONF="$HOME/.tmux.conf"

# Set zsh as default shell for tmux
if ! grep -qxF 'set-option -g default-shell /usr/bin/zsh' "$TMUX_CONF" 2>/dev/null; then
    echo 'set-option -g default-shell /usr/bin/zsh' >> "$TMUX_CONF"
fi

# Add basic tmux configuration if file is empty or doesn't exist
if [[ ! -f "$TMUX_CONF" ]] || [[ ! -s "$TMUX_CONF" ]]; then
    cat > "$TMUX_CONF" <<'EOF'
# Set zsh as default shell and terminal to xterm-256color
set-option -g default-shell /usr/bin/zsh
set -g default-terminal "xterm-256color"

# Reload config file
bind r source-file ~/.tmux.conf \; display-message "TMUX Config reloaded!"

## Set the displaying of seconds
set -g status-right "%H:%M:%S"
set -g status-interval 1

set -g history-limit 10000

# switch panes using Alt-arrow without prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

## Vim-like pane navigation
bind -n 'M-h' select-pane -L
bind -n 'M-j' select-pane -D
bind -n 'M-k' select-pane -U
bind -n 'M-l' select-pane -R

## Split panes using Ctrl-Alt-arrow without prefix
bind -n 'C-M-h' split-window -h
bind -n 'C-M-l' split-window -h
bind -n 'C-M-j' split-window -v
bind -n 'C-M-k' split-window -v

# Enable mouse support
# set -g mouse on

EOF
fi

echo "✔ Tmux configuration complete"
echo "💡 Tmux aliases (tl, ta) will be set up by dev-tools script"