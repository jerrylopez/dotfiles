# Complete `c` with the project directories in $PROJECTS
_c() {
    _files -W "$PROJECTS" -/
}
compdef _c c

# Complete `co` like `git checkout`
compdef _git co=git-checkout

# |----------------------------------------------------------------
# | wt
# |----------------------------------------------------------------

# The worktrees of the project the current directory is in. `wt remove` takes a
# branch name or the directory it produced, so both are offered: the directory is
# what `wt list` prints, the branch is what you are more likely to remember.
_wt_worktrees() {
    local -a dirs branches
    dirs=(${(f)"$(wt list 2>/dev/null | awk 'NR > 1 { print $1 }')"})
    branches=(${(f)"$(wt list 2>/dev/null | awk 'NR > 1 && NF >= 3 { print $3 }')"})

    _describe -t worktrees 'worktree' dirs
    _describe -t branches 'branch' branches
}

# Branches that could name a new worktree. Remote-only branches are offered
# without their `origin/` prefix, because that is the name `wt add` takes to
# start tracking one.
_wt_branches() {
    local -a branches
    branches=(${(f)"$(git for-each-ref --format='%(refname:short)' \
        refs/heads refs/remotes/origin 2>/dev/null |
        sed 's|^origin/||' | grep -v '^HEAD$' | sort -u)"})

    _describe -t branches 'branch' branches
}

# Anything a new branch can be based on, so `origin/` is kept here.
_wt_refs() {
    local -a refs
    refs=(${(f)"$(git for-each-ref --format='%(refname:short)' \
        refs/heads refs/remotes refs/tags 2>/dev/null)"})

    _describe -t refs 'ref' refs
}

_wt() {
    local curcontext="$curcontext" state
    local -a commands

    commands=(
        'init:clone a repository into a new wt project'
        'add:create a worktree, then run .wt/hooks/add'
        'remove:run .wt/hooks/remove, then destroy worktrees'
        'list:list this project'"'"'s worktrees'
        'claude:choose a worktree and start claude in it'
        'hook:answer Claude Code'"'"'s worktree hooks on stdin'
    )

    _arguments -C '1: :->command' '*:: :->argument'

    case $state in
        command)
            _describe -t commands 'wt command' commands
            ;;
        argument)
            case $words[1] in
                add)
                    _arguments \
                        '--base[branch from this ref instead of the default]:ref:_wt_refs' \
                        '1:branch:_wt_branches'
                    ;;
                remove)
                    # Repeatable, since remove takes any number of worktrees.
                    _arguments \
                        '(--force -f)'{--force,-f}'[discard uncommitted changes]' \
                        '*:worktree:_wt_worktrees'
                    ;;
                init)
                    _arguments \
                        '1:repository:' \
                        '2:directory:_files -/'
                    ;;
                claude)
                    # Only -w is wt's to complete; the rest of the line belongs
                    # to claude and is passed through untouched.
                    _arguments \
                        '(-w --worktree)'{-w,--worktree}'[open this worktree instead of choosing]:worktree:_wt_worktrees' \
                        '*::claude argument:'
                    ;;
            esac
            ;;
    esac
}

compdef _wt wt
