#!/usr/bin/env bash
# Render every theme-render template for both palettes and compare the result
# against committed golden files. This is the theme engine's only output check:
# it catches a template or palette edit that changes (or breaks) a rendered
# config — dunstrc, the waybar bar, alacritty colors, and the rest.
#
#   render-golden.sh            verify against goldens (CI mode; non-zero on drift)
#   render-golden.sh --update   regenerate goldens after an intended change
#
# It reproduces ONLY the envsubst render, not theme-render's daemon reloads,
# wallpaper, gsettings or VSCodium steps — those are guarded side-effects, not
# config output. Palette resolution goes through the real load.sh, and the
# template->dest list is parsed straight out of theme-render, so this harness
# can't silently drift from what the WM actually renders.
set -euo pipefail

TESTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$TESTDIR/../.." && pwd)"
THEME_DIR="$REPO/common/theme/.config/theme"
TMPL="$THEME_DIR/templates"
GOLDEN="$TESTDIR/golden"

update=0
case "${1:-}" in
    --update) update=1 ;;
    "") ;;
    *) echo "usage: render-golden.sh [--update]" >&2; exit 2 ;;
esac

command -v envsubst >/dev/null || { echo "envsubst (gettext) is required" >&2; exit 2; }

# The (template -> dest) pairs, parsed from theme-render's `render` calls so a
# new/removed/renamed render is reflected here automatically.
mapfile -t render_lines < <(grep -E '^render ' "$THEME_DIR/theme-render")
[ "${#render_lines[@]}" -gt 0 ] || { echo "no 'render' lines found in theme-render" >&2; exit 2; }

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

# 1. Render both palettes into $workdir/out/<theme>/, each in an isolated env so
#    dark's exports can't bleed into light's render.
for theme in dark light; do
    cache="$workdir/cache-$theme"; mkdir -p "$cache/theme"
    printf '%s\n' "$theme" > "$cache/theme/current"
    (
        export XDG_CONFIG_HOME="$REPO/common/theme/.config"
        export XDG_CACHE_HOME="$cache"
        # shellcheck disable=SC1090
        . "$THEME_DIR/load.sh"
        # Host-independent stand-in for the one template that embeds an absolute
        # home path (dunstrc); the real render substitutes the live $HOME.
        export THEME_home='$HOME'
        vars="$(compgen -A export | grep '^THEME_' | sed 's/^/$/' | paste -sd ' ')"
        for line in "${render_lines[@]}"; do
            read -r _ tmpl dest <<<"$line"
            rel="${dest#\"\$HOME/}"; rel="${rel%\"}"
            out="$workdir/out/$theme/$rel"
            mkdir -p "$(dirname "$out")"
            envsubst "$vars" < "$TMPL/$tmpl" > "$out"
        done
    ) || { echo "render failed for palette '$theme'" >&2; exit 1; }
done

# 2. Verify (or update) each rendered file against its golden.
fail=0
for theme in dark light; do
    while IFS= read -r out; do
        rel="${out#"$workdir/out/$theme/"}"
        # An unsubstituted ${THEME_name} means a template references a var no
        # palette defines — a broken config that only shows on that theme. Match
        # the same shape theme-render treats as a reference (THEME_ + >=1 name
        # char), so literal doc text like `${THEME_*}` in a comment isn't flagged.
        if grep -qE '\$\{?THEME_[A-Za-z0-9_]+' "$out"; then
            echo "DRIFT: $theme/$rel has an unsubstituted \${THEME_name} (undefined palette var)"
            fail=1
        fi
        gold="$GOLDEN/$theme/$rel"
        if [ "$update" -eq 1 ]; then
            mkdir -p "$(dirname "$gold")"
            cp "$out" "$gold"
        elif [ ! -f "$gold" ]; then
            echo "MISSING GOLDEN: $theme/$rel — run: tests/theme/render-golden.sh --update"
            fail=1
        elif ! diff -u --label "golden/$theme/$rel" --label "rendered/$theme/$rel" "$gold" "$out"; then
            echo "^ $theme/$rel differs from its golden (run --update if the change is intended)"
            fail=1
        fi
    done < <(find "$workdir/out/$theme" -type f | sort)
done

if [ "$update" -eq 1 ]; then
    echo "goldens regenerated under tests/theme/golden/"
elif [ "$fail" -eq 0 ]; then
    echo "theme render matches goldens for both palettes"
fi
exit "$fail"
