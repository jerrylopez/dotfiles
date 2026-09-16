#!/usr/bin/env bash
# Toggle AeroSpace between the laptop and external-monitor configs by
# repointing ~/.aerospace.toml, then reloading.
#
# Bound to hyper+` in both configs. Any new config must keep that binding,
# otherwise there is no way to switch back from it.
set -euo pipefail

dir="$HOME/.dotfiles/config/aerospace"
link="$HOME/.aerospace.toml"

case "$(readlink "$link" 2>/dev/null)" in
  *external.toml) target=laptop ;;
  *)              target=external ;;
esac

ln -sfn "$dir/$target.toml" "$link"
aerospace reload-config

# on-window-detected normally only fires for new windows, so windows already
# open would keep the previous config's workspace and layout. Replay the rules
# over everything that is already on screen.
# stderr is just per-window "already in that workspace/layout" notices; a real
# failure still aborts via the exit code.
aerospace run-callback --for-every-window on-window-detected 2>/dev/null
