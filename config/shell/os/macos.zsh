# Sourced by config/zsh/zshrc on macOS only, after every shared file and
# before compinit.

# |----------------------------------------------------------------
# | Paths
# |----------------------------------------------------------------

# Homebrew
export PATH="/opt/homebrew/bin:$PATH"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

fpath=(/opt/homebrew/share/zsh/site-functions $fpath)

# |----------------------------------------------------------------
# | Variables
# |----------------------------------------------------------------

# The project folder that we can `c [tab]` to
export PROJECTS=/Volumes/CaseSensitive/Code

export EDITOR='code'

# |----------------------------------------------------------------
# | Herd
# |----------------------------------------------------------------

# Herd is macOS-only, so its exports do not belong in the shared config. Note
# that Herd rewrites ~/.zshrc when it launches and that file is a symlink into
# this repo, so these reappear in config/zsh/zshrc and have to be moved back
# here by hand every so often.
export PATH="$HOME/Library/Application Support/Herd/bin":$PATH

export HERD_PHP_81_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/81"
export HERD_PHP_83_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/83"
export HERD_PHP_84_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/84"
export HERD_PHP_85_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/85"
export HERD_PHP_86_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/86"
