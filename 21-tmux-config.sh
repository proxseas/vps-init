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

# Install TPM (Tmux Plugin Manager) if not present
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    echo "Installing TPM (Tmux Plugin Manager)..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    echo "✔ TPM installed"
else
    echo "✔ TPM already installed"
fi

# Create comprehensive tmux configuration
cat > "$TMUX_CONF" <<'EOF'
# Set zsh as default shell and terminal to xterm-256color
set-option -g default-shell /bin/zsh
set -g default-terminal "xterm-256color"

## Set the displaying of seconds
set -g status-right "%H:%M:%S %m/%d"
set -g status-interval 1

set -g history-limit 10000

## Plugins
set -g @plugin 'tmux-plugins/tpm'         # Always first

# Below the plugin lines — initialize TPM:
run '~/.tmux/plugins/tpm/tpm'

# set -g mouse on

setw -g mode-keys vi

## Reload Prefix+r
bind r source-file ~/.tmux.conf \; display "Manually reloaded TMUX config"

## Alt+m => toggle zoom for active pane
bind -n M-m resize-pane -Z

# Switch panes using Alt-arrow without prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

## Split windows using C-M-h|j|k|l
bind -n 'C-M-h' split-window -h
bind -n 'C-M-l' split-window -h
bind -n 'C-M-j' split-window -v
bind -n 'C-M-k' split-window -v

## Alt+hjkl => select pane
bind -n M-h select-pane -L
bind -n M-j select-pane -D
bind -n M-k select-pane -U

## this one is more tricky
# unbind any old literal "l"
unbind -n M-l
bind -n M-l select-pane -R

## Shift+Alt+hjkl =>  Resize panes
unbind -n M-H; bind -n M-H resize-pane -L 5
unbind -n M-J; bind -n M-J resize-pane -D 5
unbind -n M-K; bind -n M-K resize-pane -U 5
unbind -n M-L; bind -n M-L resize-pane -R 5

## Rename Pane
bind , command-prompt -I "#W" "rename-window '%%'"

# switch windows using Shift-arrow without prefix
bind -n S-Left previous-window
bind -n S-Right next-window

## more visual customizations
### panes
set -g pane-border-style 'fg=yellow'
set -g pane-active-border-style 'fg=green'
### status bar
set -g status-style 'fg=green'
setw -g window-status-current-style 'fg=black bg=green'
setw -g window-status-current-format ' #I #W #F '
setw -g window-status-style 'fg=green bg=black'
setw -g window-status-format ' #I #[fg=white]#W #[fg=yellow]#F '
setw -g window-status-bell-style 'fg=black bg=yellow bold'
# clock mode
setw -g clock-mode-colour yellow
EOF

echo "✔ Tmux configuration complete"
echo "💡 Tmux aliases (tl, ta) will be set up by dev-tools script"