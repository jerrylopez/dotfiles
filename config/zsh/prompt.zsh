# A badge prompt: a coloured pill naming the machine, the working directory,
# and then the cursor on a line of its own.
#
# The pill puts the hostname somewhere it cannot be missed, which is what the
# old right-aligned hostname was for — a shell on the VPS should not look like
# a shell on the laptop. The pill changes colour for root, for SSH, and when
# the last command failed, so the same glance answers three more questions.

# Nerd Font codepoints, written as escapes rather than pasted in so this file
# stays readable in an editor that has no patched font loaded.
typeset -g prompt_cap_left=$'\ue0b6'         # left half circle
typeset -g prompt_cap_right=$'\ue0b4'        # right half circle
typeset -g prompt_glyph_user=$'\uf155'       # dollar sign
typeset -g prompt_glyph_root=$'\uf4df'       # hash
typeset -g prompt_glyph_ssh=$'\U000f0318'    # network
typeset -g prompt_glyph_error=$'\uea87'      # crossed circle
typeset -g prompt_glyph_dir=$'\ue5fe'        # folder
typeset -g prompt_glyph_cursor=$'\U000f17a9' # arrow turning down

# Colours from the Ghostty palette in config/ghostty/config, so that orange or
# red mean the same thing in the prompt as they do in everything else. The
# badge text is the terminal background: white is the more obvious choice, but
# it is unreadable on the lighter two of these four colours.
typeset -gA prompt_color=(
  user  '#f2a272'
  root  '#c574dd'
  ssh   '#5adecd'
  error '#ff4971'
  path  '#8b8d98'
)
typeset -g prompt_badge_fg='#1d1f28'

# A Linux console has no Nerd Font and would draw the lot as tofu, so fall back
# to punctuation that every font has. Set PROMPT_NO_GLYPHS to force it.
if [[ $TERM == linux || -n $PROMPT_NO_GLYPHS ]]
then
  prompt_cap_left='' prompt_cap_right=''
  prompt_glyph_user='$' prompt_glyph_root='#'
  prompt_glyph_ssh='*' prompt_glyph_error='!'
  prompt_glyph_dir=''
  prompt_glyph_cursor='->'
fi

# Without the caps there is nothing to hold the badge off its contents, so the
# padding has to be spelled out instead.
typeset -g prompt_pad=''
[[ -z $prompt_cap_left ]] && prompt_pad=' '

# The cursor line is indented to sit its arrow directly under the glyph in the
# badge above, so measure whatever comes before that glyph: the cap in one
# mode, the padding that stands in for it in the other.
typeset -g prompt_indent=''
[[ -n $prompt_cap_left ]] && prompt_indent+=' '
prompt_indent+=$prompt_pad

# This prompt puts the hostname on the left, so nothing belongs on the right.
# The version that did was exported, which means a shell started from one of
# those still has it in its environment and would draw it alongside the badge.
unset RPROMPT

precmd() {
  # Before anything else runs and overwrites it.
  local last_status=$?

  title "zsh" "%m" "%55<...<%~"

  # 130 is Ctrl-C, which is a thing you meant to do rather than a failure.
  local accent glyph label='%m'
  if (( last_status != 0 && last_status != 130 ))
  then
    accent=$prompt_color[error] glyph=$prompt_glyph_error
  elif (( EUID == 0 ))
  then
    accent=$prompt_color[root] glyph=$prompt_glyph_root
  elif [[ -n $SSH_CONNECTION ]]
  then
    accent=$prompt_color[ssh] glyph=$prompt_glyph_ssh
  else
    accent=$prompt_color[user] glyph=$prompt_glyph_user
  fi

  # Who you are only matters where it might not be you, so the username joins
  # the hostname over SSH and under su, and stays out of the way otherwise.
  if [[ -n $SSH_CONNECTION || ( -n $LOGNAME && $USER != $LOGNAME ) ]]
  then
    label='%n@%m'
  fi

  local identity="%F{$accent}${prompt_cap_left}%K{$accent}%F{$prompt_badge_fg}"
  identity+="${prompt_pad}${glyph} ${label}${prompt_pad}%f%k"
  identity+="%F{$accent}${prompt_cap_right}%f"

  # Deep paths keep their first component and their last two, so that ~ or the
  # volume still shows and the middle is what gets dropped.
  local path_segment="%F{$prompt_color[path]}%(4~|%-1~/.../%2~|%~)%f"
  if [[ -n $prompt_glyph_dir ]]
  then
    path_segment="%F{$accent}${prompt_glyph_dir}%f $path_segment"
  fi

  PROMPT=$'\n'"${identity} ${path_segment}"$'\n'"${prompt_indent}%F{$accent}${prompt_glyph_cursor}%f "
}
