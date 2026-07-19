# Complete `c` with the project directories in $PROJECTS
_c() {
    _files -W "$PROJECTS" -/
}
compdef _c c
