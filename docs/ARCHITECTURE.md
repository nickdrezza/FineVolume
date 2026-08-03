# Architecture

Fine Volume is deliberately small and split into two Swift targets.

## FineVolumeCore

`FineVolumeCore` owns behavior that does not depend on the menu-bar UI:

- `VolumeMath` performs clamped 1% adjustments.
- `SystemVolumeController` resolves the current default output device and reads
  or writes its virtual main-volume property through Core Audio.

The output device is resolved for every operation so changing headphones,
Bluetooth devices, or displays does not leave the app controlling a stale
device.

## FineVolume app

The executable target contains five small pieces:

- `AppDelegate` builds the menu and coordinates user-visible state.
- `MediaKeyManager` filters the two intended volume media-key combinations.
- `MediaKeyPermissionManager` checks and requests the associated macOS privacy
  access.
- `LaunchAtLoginManager` wraps `SMAppService.mainApp`.
- `main.swift` starts the accessory application without a Dock icon.

## Privacy boundary

Fine Volume uses an active Core Graphics event tap, which macOS protects with
Input Monitoring and Accessibility permission. The callback inspects only
system-defined media-key events, consumes Volume Up or Down only while both
Control and Option are held, and passes every other event through unchanged.
Core Audio volume properties contain numeric device-control values, not audio
samples.

## Packaging

`Scripts/package.sh` builds arm64 and x86_64 together, creates an app bundle in
a clean temporary directory, applies an ad-hoc development signature, strips
extended metadata, and creates a deterministic ZIP suitable for a GitHub
release. Production releases can replace the ad-hoc signature with Developer ID
signing and notarization without changing app code.
