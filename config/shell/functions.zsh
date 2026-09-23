g() {
    php "$PROJECTS/geoffrey/artisan" "$@"
}

c() {
    cd "$PROJECTS/$1"
}

wt() {
    cd "$WORKTREES/$1"
}

# Inside a linked git worktree, $parent is the main checkout it was created
# from, so `cp $parent/.env .` works from anywhere in the tree. It is unset
# everywhere else, so a stale value never points at the wrong repo.
_set_worktree_parent() {
    local dirs
    dirs=(${(f)"$(git rev-parse --path-format=absolute --git-dir --git-common-dir 2>/dev/null)"})

    if [[ ${#dirs} -eq 2 && $dirs[1] != $dirs[2] && $dirs[2]:t == .git ]]; then
        parent=$dirs[2]:h
    else
        unset parent
    fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd _set_worktree_parent
_set_worktree_parent

update() {
    $DOTFILES/script/update
}

extract () {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)  tar -jxvf $1                        ;;
            *.tar.gz)   tar -zxvf $1                        ;;
            *.bz2)      bunzip2 $1                          ;;
            *.dmg)      hdiutil mount $1                    ;;
            *.gz)       gunzip $1                           ;;
            *.tar)      tar -xvf $1                         ;;
            *.tbz2)     tar -jxvf $1                        ;;
            *.tgz)      tar -zxvf $1                        ;;
            *.zip)      unzip $1                            ;;
            *.ZIP)      unzip $1                            ;;
            *.pax)      cat $1 | pax -r                     ;;
            *.pax.Z)    uncompress $1 --stdout | pax -r     ;;
            *.rar)      unrar x $1                          ;;
            *.Z)        uncompress $1                       ;;
            *)          echo "'$1' cannot be extracted/mounted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
