#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 22-vim-config.sh - Vim configuration setup (NO SUDO)
# =============================================================================
# This script configures vim with vim-plug and essential plugins.
# USAGE: ./22-vim-config.sh (as regular user)
# =============================================================================

# Source utilities
source "$(dirname "$0")/utils.sh"

# Check if running with sudo (should NOT be)
check_not_root

# ---- Vim + vim-plug ----
print_section "Vim Configuration"

VIM_AUTOLOAD="$HOME/.vim/autoload/plug.vim"
VIMRC="$HOME/.vimrc"

# Install vim-plug if not present
if [ ! -f "$VIM_AUTOLOAD" ]; then
  echo "Installing vim-plug..."
  curl -fLo "$VIM_AUTOLOAD" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# Create minimal ~/.vimrc if missing
if [ ! -f "$VIMRC" ]; then
  echo "Creating vim configuration..."
  cat > "$VIMRC" <<'EOF'
set number relativenumber mouse=a
set hlsearch incsearch ignorecase wrap autoindent cursorline tabstop=2
syntax on

call plug#begin('~/.vim/plugged')
  Plug 'sjl/badwolf'
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-commentary'
  Plug 'stephpy/vim-yaml'
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
call plug#end()

" Set colorscheme with fallback
silent! colorscheme badwolf

" FZF key bindings
nnoremap <C-p> :Files<CR>
nnoremap <C-f> :Rg<CR>
EOF

  # Install vim plugins with timeout to prevent hanging
  echo "Installing vim plugins..."
  timeout 60 vim +PlugInstall +qall </dev/null 2>/dev/null || {
    echo "Vim plugin installation failed or timed out, continuing..."
  }
fi

echo "✔ Vim configuration complete"
echo "💡 Use :PlugInstall in vim to install plugins manually if needed"