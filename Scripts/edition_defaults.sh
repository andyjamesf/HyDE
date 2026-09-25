#!/usr/bin/env bash
# First-install look of the Quickshell Edition: the Drawbridge theme, macOS-like animations and the
# Morphing Island as the active shell. Each default is applied only when nothing was chosen yet, so
# installing over an existing HyDE keeps the user's theme, animations and shell. Run by install.sh
# after the themes are installed and before the theme is applied.
set -euo pipefail

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hyde"
staterc="$state_dir/staterc"
themes_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hyde/themes"
mkdir -p "$state_dir"
touch "$staterc"

has_key() { grep -q "^$1=\"\?[^\"]\+" "$staterc"; }

# Theme: Drawbridge, if it was installed (themepatcher.lst).
if ! has_key HYDE_THEME && [[ -d "$themes_dir/Drawbridge" ]]; then
    echo 'HYDE_THEME="Drawbridge"' >>"$staterc"
fi

# Animations: macOS-like (HyDE's Lua selector reads the staterc until a choice is made).
if ! has_key HYPR_ANIMATION; then
    echo 'HYPR_ANIMATION="macos"' >>"$staterc"
fi

# Shell: the Morphing Island, unless a choice exists (`island on|off` creates this folder).
island_state="${XDG_STATE_HOME:-$HOME/.local/state}/morphing-island"
if [[ ! -d "$island_state" ]]; then
    mkdir -p "$island_state"
    touch "$island_state/active"
fi
