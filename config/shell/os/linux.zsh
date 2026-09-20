# Sourced by config/zsh/zshrc on Linux only, after every shared file and
# before compinit.

# |----------------------------------------------------------------
# | Paths
# |----------------------------------------------------------------

# Homebrew. shellenv rather than a bare PATH export because on Linux brew also
# has to set HOMEBREW_PREFIX, MANPATH and INFOPATH, which a PATH line misses.
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]
then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fpath=($HOMEBREW_PREFIX/share/zsh/site-functions $fpath)
fi

# |----------------------------------------------------------------
# | Variables
# |----------------------------------------------------------------

# The project folder that we can `c [tab]` to
export PROJECTS=$HOME/code

# This box is headless, so the Mac's `code` is not an option here.
export EDITOR='nvim'
