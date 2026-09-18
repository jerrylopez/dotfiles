autoload colors && colors

# The directory line, with the hostname pushed to the far right. The prompts
# are otherwise identical on every machine, so without the hostname it is easy
# to lose track of whether a shell is local or on the VPS.
#
# RPROMPT is the usual home for something like this, but it only ever renders
# on the line the cursor sits on, so the spacing is worked out by hand here:
# expand both halves to plain text, measure them, and fill the gap between. A
# terminal too narrow to hold both drops the hostname rather than wrapping it.
directory_name() {
  local dir_fmt='%1/%/' host_fmt='%m' dir host pad

  # Doubled so that a `%` in a path is not taken for a prompt escape when zsh
  # expands this line.
  dir="${${(%)dir_fmt}//\%/%%}"
  host="${${(%)host_fmt}//\%/%%}"
  pad=$(( COLUMNS - ${#dir} - ${#host} ))

  if (( pad < 2 ))
  then
    print -rn -- "%{$fg_bold[cyan]%}${dir}%{$reset_color%}"
  else
    print -rn -- "%{$fg_bold[cyan]%}${dir}%{$reset_color%}${(l:$pad:: :)}%{$fg_bold[yellow]%}${host}%{$reset_color%}"
  fi
}

export PROMPT=$'\n$(directory_name)\n-> '
set_prompt () {
  export RPROMPT="%{$fg_bold[cyan]%}%{$reset_color%}"
}

precmd() {
  title "zsh" "%m" "%55<...<%~"
  set_prompt
}
