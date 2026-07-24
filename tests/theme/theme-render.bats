#!/usr/bin/env bats
# Behavioural tests for theme-render's two trickiest mechanisms — the ones the
# golden test can't reach because they're about *how* files are written, not
# what ends up in them:
#
#   * atomic writes  — render() renders to a temp on the same filesystem and
#                      renames over the REAL file behind a stow symlink, so a
#                      crash never leaves a half-written config and the stow
#                      link is never clobbered.
#   * flock serialization — a single render is re-exec'd under flock so two
#                      concurrent renders can't interleave, and `flock -o`
#                      keeps the lock off the fds inherited by the daemons the
#                      render backgrounds (the leak that would wedge every
#                      later theme switch).
#
# These drive the REAL theme-render (never a copy) against a throwaway $HOME, so
# they stay honest. Everything that would touch the live session (gsettings, the
# wallpaper daemon) is shadowed by stubs, so the suite is safe to run on your own
# machine, not just in CI.

setup() {
    REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    # Point theme-render (and the load.sh it sources) at the repo's real theme
    # dir + templates, but render into a throwaway HOME.
    export XDG_CONFIG_HOME="$REPO/common/theme/.config"
    RENDER="$XDG_CONFIG_HOME/theme/theme-render"
    export HOME="$BATS_TEST_TMPDIR/home"
    export XDG_CACHE_HOME="$BATS_TEST_TMPDIR/cache"
    LOCK="$XDG_CACHE_HOME/theme/render.lock"
    mkdir -p "$HOME/.config" "$XDG_CACHE_HOME/theme"
    printf 'dark\n' > "$XDG_CACHE_HOME/theme/current"
    unset SWAYSOCK THEME_LOCK_HELD

    # Capture the real envsubst BEFORE shadowing PATH (the serialization test
    # wraps it). Then shadow gsettings: it's the one daemon-poke that runs even
    # under --no-reload, and unstubbed it would flip the developer's live GTK/Qt
    # theme when the suite is run locally.
    STUB="$BATS_TEST_TMPDIR/stub"
    mkdir -p "$STUB"
    REAL_ENVSUBST="$(command -v envsubst)"
    export REAL_ENVSUBST
    printf '#!/bin/sh\nexit 0\n' > "$STUB/gsettings"
    chmod +x "$STUB/gsettings"
    export PATH="$STUB:$PATH"
}

teardown() {
    # The leak test backgrounds a stub daemon that outlives the render; reap it.
    if [ -f "$BATS_TEST_TMPDIR/sleeper.pid" ]; then
        kill "$(cat "$BATS_TEST_TMPDIR/sleeper.pid")" 2>/dev/null || true
    fi
}

@test "render writes through a stow symlink to the real file, leaving the link intact" {
    # Reproduce stow linking an individual file: a real file living in the
    # "repo", and ~/.config/waybar/config a symlink pointing at it. A naive
    # render (> "$dst") would replace the symlink with a regular file and orphan
    # the repo copy; render()'s readlink -f + rename must update the real file
    # and leave the link untouched.
    real="$BATS_TEST_TMPDIR/repo/waybar-config"
    mkdir -p "$(dirname "$real")" "$HOME/.config/waybar"
    printf 'OLD CONTENT\n' > "$real"
    ln -s "$real" "$HOME/.config/waybar/config"

    run "$RENDER" --no-reload
    [ "$status" -eq 0 ]

    # The stow link itself survives and still points where it did.
    [ -L "$HOME/.config/waybar/config" ]
    [ "$(readlink "$HOME/.config/waybar/config")" = "$real" ]
    # The real file behind it got a fresh, fully-substituted render.
    [ "$(cat "$real")" != "OLD CONTENT" ]
    run cat "$real"
    [[ "$output" != *'${THEME_'* ]]
    # And no temp file was left stranded next to the target.
    run find "$(dirname "$real")" -name '*.tmp-theme.*'
    [ -z "$output" ]
}

@test "a successful render leaves no .tmp-theme.* temp files anywhere" {
    run "$RENDER" --no-reload
    [ "$status" -eq 0 ]
    run bash -c 'find "$HOME" -name "*.tmp-theme.*" -print'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "concurrent renders are serialized by the flock (no interleaving)" {
    command -v flock >/dev/null || skip "flock not available"
    log="$BATS_TEST_TMPDIR/calls.log"
    : > "$log"
    # An envsubst wrapper that stamps the calling render's pid ($PPID — envsubst
    # is a direct child of theme-render) on every invocation and dawdles, then
    # delegates to the real one. If the lock did NOT serialize, the two renders'
    # stamps would interleave in the log; if it did, one render holds the lock
    # for its whole lifetime, so all its stamps land before the other's.
    cat > "$STUB/envsubst" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$PPID" >> "$log"
sleep 0.05
exec "$REAL_ENVSUBST" "\$@"
EOF
    chmod +x "$STUB/envsubst"

    "$RENDER" --no-reload &
    "$RENDER" --no-reload &
    wait

    # Every line is one render's pid. Serialized => the log is one pid's runs
    # then the other's => at most a single pid transition.
    [ -s "$log" ]
    transitions="$(awk 'NR>1 && $0!=prev{n++} {prev=$0} END{print n+0}' "$log")"
    [ "$transitions" -le 1 ]
}

@test "the flock releases right after render — fd not leaked to daemons (flock -o)" {
    command -v flock >/dev/null || skip "flock not available"
    # Enable the wallpaper branch, which backgrounds awww-daemon — a process
    # that outlives the render. Without `flock -o` the render would hand it the
    # inherited lock fd, and it would pin the lock for its (30s) lifetime.
    export SWAYSOCK="$BATS_TEST_TMPDIR/fake.sock"
    cat > "$STUB/awww-daemon" <<EOF
#!/usr/bin/env bash
echo "\$\$" > "$BATS_TEST_TMPDIR/sleeper.pid"
exec sleep 30
EOF
    # `awww img` returns instantly so the readiness loop doesn't spin, and pgrep
    # reports the daemon absent so theme-render actually spawns our stub.
    printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB/awww"
    printf '#!/usr/bin/env bash\nexit 1\n' > "$STUB/pgrep"
    chmod +x "$STUB/awww-daemon" "$STUB/awww" "$STUB/pgrep"

    run "$RENDER" --no-reload
    [ "$status" -eq 0 ]
    # The daemon really did start (otherwise the test proves nothing)...
    [ -f "$BATS_TEST_TMPDIR/sleeper.pid" ]
    # ...and yet the lock is free the instant the render returns.
    run flock -n "$LOCK" -c 'exit 0'
    [ "$status" -eq 0 ]
}

@test "THEME_LOCK_HELD short-circuits the flock re-exec (no recursion)" {
    # The re-exec'd instance carries THEME_LOCK_HELD=1 so it renders in-process
    # instead of locking again. With the marker pre-set, flock must never be
    # invoked — a shim records the violation if it is.
    cat > "$STUB/flock" <<EOF
#!/usr/bin/env bash
touch "$BATS_TEST_TMPDIR/flock-was-called"
exit 0
EOF
    chmod +x "$STUB/flock"

    export THEME_LOCK_HELD=1
    run "$RENDER" --no-reload
    [ "$status" -eq 0 ]
    [ ! -f "$BATS_TEST_TMPDIR/flock-was-called" ]
}
