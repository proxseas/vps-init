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
# Set zsh as default shell
set-option -g default-shell /usr/bin/zsh

# Enable mouse support
set -g mouse on

# Set prefix to Ctrl-a
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Split panes using | and -
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %

# Reload config file
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"

# Don't rename windows automatically
set-option -g allow-rename off

# Start window numbering at 1
set -g base-index 1
set -g pane-base-index 1
EOF
fi

echo "✔ Tmux configuration complete"
echo "💡 Tmux aliases (tl, ta) will be set up by dev-tools script"