# Symlinks my keys from iCloud Drive to the expected location

SSH_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Documents/Personal/Security/SSH"
ln -sf "$SSH_DIR" "$HOME/.ssh"
