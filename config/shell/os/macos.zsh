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

# The sibling folder that git worktrees are checked out into
export WORKTREES=/Volumes/CaseSensitive/Worktrees

export EDITOR='code'
