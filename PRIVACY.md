# Privacy

Fine Volume is designed to do one job locally: change macOS output volume in 1%
steps.

## Data collection

Fine Volume does not collect, store, transmit, or sell personal data. It has no
analytics, telemetry, advertising SDKs, crash-reporting service, or network
client.

## System access

Fine Volume requests Accessibility and Input Monitoring permission. These are
needed to receive and consume the physical volume media-key events while other
apps are active.

The app filters exactly two key combinations:

- Control + Option + Volume Up
- Control + Option + Volume Down

It passes all other events through unchanged, including Volume Up or Down when
Control and Option are not both held. Fine Volume does not request microphone,
Screen Recording, or audio-capture permission.

The app uses Core Audio to read and write the virtual main-volume value of the
current default output device. It does not capture or inspect audio content.

## Launch at Login

Launch at Login is optional. Fine Volume asks after first-launch permission
onboarding and only registers the main app as a login item after an explicit
user choice. The setting can be changed from the menu-bar menu or System
Settings → General → Login Items.

## Verification

Fine Volume is open source. Its behavior can be reviewed in `Sources/` and the
complete app can be built without third-party dependencies.
