# Privacy

Fine Volume is designed to do one job locally: change macOS output volume in 1%
steps.

## Data collection

Fine Volume does not collect, store, transmit, or sell personal data. It has no
analytics, telemetry, advertising SDKs, crash-reporting service, or network
client.

## System access

Fine Volume does not request Accessibility, Input Monitoring, microphone,
Screen Recording, or audio-capture permission.

The app registers exactly two global hotkeys with macOS:

- Control + Option + Up Arrow
- Control + Option + Down Arrow

It is notified only when one of those registered shortcuts is activated. It
does not receive arbitrary keyboard input.

The app uses Core Audio to read and write the virtual main-volume value of the
current default output device. It does not capture or inspect audio content.

## Launch at Login

Launch at Login is optional. Fine Volume asks on first launch and only registers
the main app as a login item after an explicit user choice. The setting can be
changed from the menu-bar menu or System Settings → General → Login Items.

## Verification

Fine Volume is open source. Its behavior can be reviewed in `Sources/` and the
complete app can be built without third-party dependencies.
