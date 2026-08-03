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

The executable target contains four small pieces:

- `AppDelegate` builds the menu and coordinates user-visible state.
- `HotKeyManager` registers the two global shortcuts with macOS.
- `LaunchAtLoginManager` wraps `SMAppService.mainApp`.
- `main.swift` starts the accessory application without a Dock icon.

## Privacy boundary

The hotkey API reports only registered shortcut activations. Fine Volume does
not install an event tap or request Input Monitoring or Accessibility access.
Core Audio volume properties contain numeric device-control values, not audio
samples.

## Packaging

`Scripts/package.sh` builds arm64 and x86_64 together, creates an app bundle in
a clean temporary directory, applies an ad-hoc development signature, strips
extended metadata, and creates a deterministic ZIP suitable for a GitHub
release. Production releases can replace the ad-hoc signature with Developer ID
signing and notarization without changing app code.
