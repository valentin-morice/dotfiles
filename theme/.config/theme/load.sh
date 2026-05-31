# Resolves the active theme and sources its palette, exporting THEME_*.
# Safe to source from any shell (including under `set -e`); defaults to the
# "dark" theme when no theme has been selected or the selection is invalid.
#
# Sourced by theme-render and by the polybar scripts.

__theme_dir="${XDG_CONFIG_HOME:-$HOME/.config}/theme"
__theme_state="${XDG_CACHE_HOME:-$HOME/.cache}/theme/current"
__theme_name=dark

if [ -r "$__theme_state" ]; then
    IFS= read -r __theme_name < "$__theme_state" || __theme_name=dark
fi
[ -n "$__theme_name" ] || __theme_name=dark
[ -r "$__theme_dir/palettes/$__theme_name.sh" ] || __theme_name=dark

# shellcheck disable=SC1090
. "$__theme_dir/palettes/$__theme_name.sh"

unset __theme_dir __theme_state __theme_name
