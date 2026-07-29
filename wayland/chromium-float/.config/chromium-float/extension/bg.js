// Ping the native host whenever chromium opens a popup window, so sway can
// float it. A window.open(…, 'popup=…') child — OAuth consent, SSO hand-off,
// payment flow — maps on Wayland with app_id=chromium, byte-identical to an
// ordinary browser window, and no extension API reaches the Wayland app_id.
// The window title is the only WM-visible thing an extension can influence,
// and rewriting it would cost host permissions on every site. So instead we
// say nothing about *which* window and let the host correlate by time.
//
// Note the permission list in manifest.json: nativeMessaging only. Neither
// windows.onCreated nor the Window.type field is gated, so this extension has
// no access to page content, URLs, or tab titles whatsoever.

const HOST = "live.morice.float_popups";

let port = null;

function connect() {
    if (port) return port;
    port = chrome.runtime.connectNative(HOST);
    // Chromium reaps the host process when the port drops (browser exit, or the
    // MV3 worker being reclaimed while idle). Null it so the next popup redials
    // rather than posting into a dead port.
    port.onDisconnect.addListener(() => { port = null; });
    return port;
}

// Dial at worker start rather than lazily on the first popup: the host has to
// have its sway IPC subscription live *before* a window maps, and spawning
// python + subscribing costs ~100ms — longer than the gap between
// windows.onCreated and the Wayland surface appearing.
connect();

chrome.windows.onCreated.addListener((win) => {
    if (win.type !== "popup") return;
    try {
        connect().postMessage({ action: "float" });
    } catch (e) {
        // Worker resumed holding a stale port that hasn't fired onDisconnect
        // yet. Drop it; the next popup reconnects.
        port = null;
    }
});
