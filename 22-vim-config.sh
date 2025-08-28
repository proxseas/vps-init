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
set number relativenumber
set hlsearch incsearch ignorecase wrap autoindent cursorline tabstop=2 shiftwidth=2
syntax on

" Set spacebar as leaderkey
let mapleader = " "

call plug#begin('~/.vim/plugged')
  Plug 'sjl/badwolf'
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-commentary'
  Plug 'stephpy/vim-yaml'
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
  Plug 'machakann/vim-highlightedyank'
call plug#end()

" Set colorscheme with fallback
silent! colorscheme badwolf

" FZF key bindings
" Use <leader>f for file search (now Space+f)
nnoremap <leader>f :Files<CR>
" Use <leader>r for ripgrep search (now Space+r)
nnoremap <leader>r :Rg<CR>
" Use <leader>b for buffers (now Space+b)
nnoremap <leader>b :Buffers<CR>

" Configure Highlightedyank plugin settings
let g:highlightedyank_highlight_duration = 90
let g:highlightedyank_highlight_group = 'IncSearch'

" These create newlines like o and O but stay in normal mode
nmap zj o<Esc>k
nmap zk O<Esc>j

" Map Ctrl+Underscore to toggle line comments in normal, visual, and insert modes
nnoremap <C-_> :normal gcc<CR>
vnoremap <C-_> :normal gc<CR>
inoremap <C-_> <Esc>:normal gcc<CR>

" Both of these are needed to enable quitting via C-q
silent !stty -ixon > /dev/null 2>/dev/null

" Map Ctrl+S to save (now that it has been made available via zsh)
nnoremap <C-s> :w<CR>
inoremap <C-s> <Esc>:w<CR>a
vnoremap <C-s> <Esc>:w<CR>gv

" Map Ctrl+Q to quit
map <C-Q> :q<CR>
EOF

  # Install vim plugins with timeout to prevent hanging
  echo "Installing vim plugins..."
  timeout 60 vim +PlugInstall +qall </dev/null 2>/dev/null || {
    echo "Vim plugin installation failed or timed out, continuing..."
  }
fi

echo "✔ Vim configuration complete"
echo "💡 Use :PlugInstall in vim to install plugins manually if needed"