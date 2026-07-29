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

Deliberately no `resize`: a popup keeps the dimensions the site requested as its
sway `geometry` even while tiled, so `floating enable` alone restores exactly
the size the provider designed its flow for.

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

If popups tile anyway, check the extension's service worker console
(`chrome://extensions` → *Inspect views: service worker*) for a
`Specified native messaging host not found` error — that means the host
manifest's `allowed_origins` and the loaded extension's ID disagree.
