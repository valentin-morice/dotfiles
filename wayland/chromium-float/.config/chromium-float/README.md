# Float popups (sway)

Floats chromium `window.open` popups — OAuth consent, SSO hand-offs, payment
flows — which sway cannot otherwise tell apart from an ordinary browser window:
both map with `app_id=chromium` and a page-derived title, and no extension API
reaches the Wayland app_id.

## Pieces

- `extension/` — MV3 extension. Sole permission is `nativeMessaging`; it never
  reads page content, URLs, or tab titles. Fires on `chrome.windows.onCreated`
  when `type === "popup"` and pings the host, saying nothing about the window.
- `~/.local/bin/chromium-float-host` — the native host. Correlates that ping
  against a live `swaymsg -t subscribe` and issues `floating enable`.
- `~/.config/chromium/NativeMessagingHosts/live.morice.float_popups.json` —
  registers the host against the pinned extension ID.

The host talks raw sway IPC rather than shelling out to `swaymsg`, and blocks on
a condition variable rather than polling, because the gap between sway mapping
the window and the float landing is rendered as a tiled flash with the siblings
reflowing around it. Measured `window::new` → floating: **1.1ms**, against ~52ms
for the poll-and-subprocess version.

Being that fast costs accuracy, which is why the geometry comes from chromium
rather than from sway. At ~1ms neither side has settled: sway's idea of the
view's natural size is still the size it configured while tiling it, and the
client's first buffer — queued at that tiled size before we floated — has yet to
land. So the host takes `width`/`height` off `chrome.windows.onCreated`, applies
float + resize + centre as one comma-chained sway transaction, then re-asserts
the size for up to a second until the late commit stops overriding it. Measured
end state for a popup asking 500x600: exactly 500x600, centred.

Both halves are needed. Sizing from sway alone reproduces the tiled dimensions;
sizing once without the settle loop gets clobbered a few frames later.

A truly map-time float would need a `for_window` rule, but nothing distinguishes
a popup declaratively, and sway cannot remove a rule added at runtime without
`reload` — which would restart the three `exec_always` entries in the sway
config (waybar included) on every popup.

## One manual step per chromium profile

The extension is unpacked, so it must be loaded by hand once:

    chrome://extensions → enable Developer mode → Load unpacked
    → ~/.config/chromium-float/extension

Its ID is pinned to `bagfeaideajdfbchnmlonimgcljafbph` by the `key` field in
`manifest.json`. Without that pin the ID would derive from the install path,
which stow makes ambiguous (`~/.config/…` vs the `~/.dotfiles/…` realpath), and
the host manifest's `allowed_origins` would stop matching.

## Debugging

Chromium spawns the host with its stderr discarded, so watch sway directly:

    swaymsg -t subscribe -m '["window"]' \
      | jq -r 'select(.change=="new") | .container | "\(.app_id)  \(.name)"'

To exercise the correlation without a browser at all, point the host at a
throwaway app_id and drive it by hand:

    CHROMIUM_FLOAT_APP_ID=floattest ~/.local/bin/chromium-float-host
    # …feed it a native-messaging frame, then: alacritty --class floattest

If popups tile anyway, check the extension's service worker console
(`chrome://extensions` → *Inspect views: service worker*) for a
`Specified native messaging host not found` error — that means the host
manifest's `allowed_origins` and the loaded extension's ID disagree.
