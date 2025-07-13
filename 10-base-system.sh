apt update && apt upgrade -y

# Install and configure UFW for firewall management
apt install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable

# Install and configure SSH server and mosh for secure shell access
apt install -y openssh-server mosh
systemctl enable --now ssh
ufw allow 60000:61000/udp

# Install essential CLI tools for system management and development
apt install -y \
  git curl wget htop tmux vim ripgrep ncdu pv jq make build-essential