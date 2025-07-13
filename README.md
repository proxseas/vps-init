# VPS Setup Scripts

Automated scripts for setting up a new VPS with development tools and user environment.

## Prerequisites (As Root)

Before running any setup scripts, clone this repository:

```bash
apt update && apt install -y git
git clone https://github.com/proxseas/vps-init.git /opt/vps-init
cd /opt/vps-init
```

## Setup Options

### Option A: Fully Automated (Recommended)

Run everything as root with automatic user switching:

```bash
# As root - creates user and runs complete setup
NEW_USER=myusername ./setup.sh
```

### Option B: Step-by-Step Control

For more control over the process:

```bash
# 1. Create user account (as root)
# This automatically switches to the new user and navigates to /opt/vps-init
./00-create-user.sh myusername

# 2. You're now the new user in /opt/vps-init - run setup
./setup.sh
```

## What Gets Installed

- **System Setup**: Firewall (ufw), SSH server, essential packages
- **Shell Environment**: zsh, oh-my-zsh, fzf, vim with plugins
- **Development Tools**: eza, just, useful aliases
- **Language Tooling**: Python (uv), Node.js (fnm)
- **Container Tools**: Docker, lazydocker

## Script Details

### Scripts Overview

**Root/Sudo Required:**
```bash
sudo ./00-create-user.sh      # Create new user account
sudo ./10-base-system.sh      # System packages, firewall, SSH
sudo ./40-lang-tooling-py-node.sh  # Python, Node.js tooling
sudo ./50-container-tools.sh  # Docker and container tools
```

**User Scripts (No Sudo):**
```bash
./20-shell-env.sh   # Configure zsh, oh-my-zsh, fzf, vim
./30-dev-tools.sh   # Install eza, just, setup aliases
```

### Runtime Checks

Each script includes automatic privilege validation:
- **Sudo scripts**: Exit with error if not run with sudo
- **User scripts**: Exit with error if run with sudo

## After Setup

```bash
# Switch to zsh to use your new environment
exec zsh

# Test your tools
uv --version
fnm --version
node --version
ll  # eza-powered directory listing
```

## Manual Execution (Advanced)

If you prefer to run scripts individually:

```bash
# 1. Create user (as root) - automatically switches to user
sudo ./00-create-user.sh myusername
# You're now user 'myusername' in /opt/vps-init

# 2. Configure user environment
./20-shell-env.sh
./30-dev-tools.sh

# 3. Switch back to root for system tools
exit  # back to root
cd /opt/vps-init
sudo ./10-base-system.sh
sudo ./40-lang-tooling-py-node.sh
sudo ./50-container-tools.sh
```

## Notes

- Scripts are numbered in execution order
- The master `setup.sh` handles privilege switching automatically
- Your shell environment is configured in `~/.zshrc` and `~/.zsh_aliases`
- Tools are installed to `~/.local/bin` and added to PATH