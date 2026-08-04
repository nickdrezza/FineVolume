# Privacy

Fine Volume is designed to do one job locally: change macOS output volume in 1%
steps.

## Data collection

Fine Volume does not collect, store, transmit, or sell personal data. It has no
analytics, telemetry, advertising SDKs, crash-reporting service, or network
client.

## System access

Fine Volume requests Input Monitoring permission only when the user enables
the physical volume-key shortcut. Its event tap receives only modifier-state
changes so it can detect whether Control is held.

Fine Volume does not request Accessibility, microphone, Screen Recording, or
audio-capture permission.

The app filters exactly two key combinations:

- Control + Volume Up
- Control + Volume Down

While Control is held, Fine Volume uses Apple's public HID key-remapping API to
temporarily route those two keys to unused function keys registered to the app.
Existing user mappings are preserved, and the temporary mappings are removed
when Control is released, shortcuts are disabled, or the app quits. The app
does not receive ordinary typing. The fallback is registered through macOS's
global hot-key API.

The app uses Core Audio to read and write the virtual main-volume value of the
current default output device. It does not capture or inspect audio content.

## Launch at Login

Launch at Login is optional. Fine Volume asks on first launch and only registers
the main app as a login item after an explicit user choice. The setting can be
changed from the menu-bar menu or System Settings → General → Login Items.

## Verification

Fine Volume is open source. Its behavior can be reviewed in `Sources/` and the
complete app can be built without third-party dependencies.
