#!/usr/bin/env bash
set -euo pipefail

# 1) Docker Engine
if ! command -v docker >/dev/null; then
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg lsb-release

  # Add Docker GPG key & repo
  sudo install -d -m0755 /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo \$VERSION_CODENAME) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  sudo usermod -aG docker "$USER"

  echo "✔  Docker installed and $USER added to docker group"
else
  echo "➜  Docker already installed, skipping"
fi

# 2) Lazydocker
if ! command -v lazydocker >/dev/null; then
  curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh \
    | bash
  echo "alias lzd='lazydocker'" >> "$HOME/.zsh_aliases"
  echo "✔  Lazydocker installed and alias lzd added"
else
  echo "➜  Lazydocker already installed, skipping"
fi
