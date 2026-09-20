# Complete `c` with the project directories in $PROJECTS
_c() {
    _files -W "$PROJECTS" -/
}
compdef _c c

# Complete `co` like `git checkout`
compdef _git co=git-checkout

# Complete `wt` with the worktree directories in $WORKTREES
_wt() {
    _files -W "$WORKTREES" -/
}
compdef _wt wt
