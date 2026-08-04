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

The executable target contains eight small pieces:

- `AppDelegate` builds the menu and coordinates user-visible state.
- `MediaKeyManager` monitors Control modifier-state changes.
- `HIDVolumeKeyRemapper` temporarily remaps the physical volume usages while
  Control is held and preserves existing user mappings.
- `MediaKeyPermissionManager` checks and requests Input Monitoring access.
- `HotKeyManager` registers the no-permission arrow fallback with macOS.
- `VolumeHUD` displays successful adjustments without activating the app.
- `LaunchAtLoginManager` wraps `SMAppService.mainApp`.
- `main.swift` starts the accessory application without a Dock icon.

## Privacy boundary

Fine Volume's listen-only event tap is installed only after Input Monitoring is
authorized and requests only modifier-state events. While Control is held,
Apple's public HID key-remapping property maps Volume Up/Down to unused
function keys registered to Fine Volume. The original mapping is restored when
Control is released or the app stops. Core Audio volume properties contain
numeric device-control values, not audio samples.

## Packaging

`Scripts/package.sh` builds arm64 and x86_64 together, creates an app bundle in
a clean temporary directory, applies an ad-hoc development signature, strips
extended metadata, and creates a deterministic ZIP suitable for a GitHub
release. Production releases can replace the ad-hoc signature with Developer ID
signing and notarization without changing app code.
