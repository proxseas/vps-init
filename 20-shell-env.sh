#!/usr/bin/env bash
set -euo pipefail

# ---- 0. Ensure we're on Ubuntu and have sudo ----
if ! command -v apt >/dev/null; then
  echo "This script is for Debian/Ubuntu." >&2
  exit 1
fi

# ---- 1. Tmux default shell ----
TMUX_CONF="$HOME/.tmux.conf"
grep -qxF 'set-option -g default-shell /usr/bin/zsh' "$TMUX_CONF" 2>/dev/null \
  || echo 'set-option -g default-shell /usr/bin/zsh' >> "$TMUX_CONF"

# ---- 2. Oh My Zsh ----
# install zsh if missing
sudo apt update
sudo apt install -y zsh git curl

# non-interactive OMZ install
export RUNZSH=no CHSH=no
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSHRC="$HOME/.zshrc"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# plugins
for p in zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search; do
  if [ ! -d "$ZSH_CUSTOM/plugins/$p" ]; then
    git clone --depth=1 "https://github.com/zsh-users/$p" "$ZSH_CUSTOM/plugins/$p"
  fi
done

# enable plugins in ~/.zshrc
if grep -q '^plugins=' "$ZSHRC"; then
  sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting history-substring-search)/' "$ZSHRC"
else
  echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting history-substring-search)' >> "$ZSHRC"
fi

# ensure syntax-highlighting is sourced after OMZ
grep -q 'zsh-syntax-highlighting.zsh' "$ZSHRC" 2>/dev/null \
  || sed -i "/^source .*oh-my-zsh\.sh/a source $ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" "$ZSHRC"

# misc zsh tweaks
grep -q '^EDITOR=' "$ZSHRC" 2>/dev/null || cat >> "$ZSHRC" <<'EOF'

# User preferences
EDITOR='vim'
setopt cdablevars
export TERM='xterm-256color'

# auto-ls on cd
autoload -U add-zsh-hook
add-zsh-hook -Uz chpwd (){ ls -a; }

# load aliases if present
[ -f ~/.zsh_aliases ] && source ~/.zsh_aliases
EOF

# ---- 3. FZF ----
if [ ! -d "$HOME/.fzf" ]; then
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  yes | "$HOME/.fzf/install" --completion --key-bindings --no-update-rc
fi

# ---- 4. Vim + vim-plug ----
VIM_AUTOLOAD="$HOME/.vim/autoload/plug.vim"
if [ ! -f "$VIM_AUTOLOAD" ]; then
  curl -fLo "$VIM_AUTOLOAD" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# write minimal ~/.vimrc if missing
VIMRC="$HOME/.vimrc"
if [ ! -f "$VIMRC" ]; then
  cat > "$VIMRC" <<'EOF'
set number relativenumber mouse=a
set hlsearch incsearch ignorecase wrap autoindent cursorline tabstop=2
syntax on

call plug#begin('~/.vim/plugged')
  Plug 'sjl/badwolf'
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-commentary'
  Plug 'stephpy/vim-yaml'
call plug#end()

colorscheme badwolf
EOF
  vim +PlugInstall +qall </dev/null
fi

# ---- 5. Aliases & functions ----
cat > "$HOME/.zsh_aliases" <<'EOF'
# General
alias ll='ls -lah --group-directories-first'
alias ..='cd ..'
alias q='exit'
alias reloadzsh='source ~/.zshrc'
alias editzsh='vim ~/.zshrc'

# Python venv
alias mkvenv='python3 -m venv .venv'
alias actvenv='source .venv/bin/activate'
alias takevenv='mkvenv && actvenv && echo "Activated new venv"'

# Tmux
alias tl='tmux ls'
alias ta='tmux attach'

# Docker helper
alias lzd='lazydocker'
EOF

# ---- 6. Make Zsh the default shell ----
if [ "$(basename "$SHELL")" != "zsh" ]; then
  sudo chsh -s "$(command -v zsh)" "$USER"
  echo 'source ~/.zshrc' >> "$HOME/.zprofile"
fi

echo -e "\n✔  Shell environment setup complete. Restart your terminal or run 'exec zsh'."