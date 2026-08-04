# Fine Volume

[![CI](https://github.com/nickdrezza/FineVolume/actions/workflows/ci.yml/badge.svg)](https://github.com/nickdrezza/FineVolume/actions/workflows/ci.yml)
[![Latest release](https://img.shields.io/github/v/release/nickdrezza/FineVolume?display_name=tag&sort=semver)](https://github.com/nickdrezza/FineVolume/releases/latest)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-black)](https://support.apple.com/macos)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Fine Volume is a tiny, native macOS menu-bar app that changes system volume in
one-percentage-point steps.

The current public release is **v0.5.0**. It is open source, has no third-party
dependencies, and is distributed as a universal Apple Silicon + Intel app.

## Shortcuts

- `Control + Volume Up` increases volume by 1%
- `Control + Volume Down` decreases volume by 1%

While Control is held, Fine Volume uses Apple's HID key-remapping API to route
the two physical volume keys to its 1% handler. The mapping is removed as soon
as Control is released, so unmodified volume keys remain entirely native.

If Input Monitoring is not available, the fallback is
`Control + Option + Command + Shift + Up/Down Arrow`.

Each adjustment displays a temporary volume HUD with the new percentage and a
progress bar. The menu-bar speaker icon also shows the current volume and lets
you disable the shortcuts or change the Launch at Login setting.

## Why Fine Volume?

The Mac's volume keys use relatively large steps. Fine Volume provides
predictable 1% adjustments while preserving the normal behavior of the volume
keys when the extra modifier is not held.

## Permissions

Fine Volume needs Input Monitoring permission to detect when Control is held.
Its event tap receives only modifier-state changes; it does not monitor normal
typing. The physical keys are remapped through Apple's public HID API, which
requires no special privilege. Fine Volume does not request Accessibility,
microphone, audio-recording, Screen Recording, or network access. The arrow
fallback works without Input Monitoring and is registered through macOS's
global hot-key API.

Core Audio changes the current output device's volume directly. The optional
Launch at Login feature is registered through Apple's Service Management API
and remains visible and controllable in System Settings → General → Login Items.

On first launch, Fine Volume explains its shortcuts, then separately asks
whether it should launch at login. It never enables that setting without the
user's choice.

Read the complete [privacy statement](PRIVACY.md).

## Requirements

- macOS 13 Ventura or later
- Apple Silicon or Intel Mac
- An output device with software-controllable system volume

Some HDMI, USB, aggregate, and professional audio devices do not expose a
settable system volume. Fine Volume reports that limitation in its menu instead
of silently failing.

## Install

1. Download `FineVolume.zip` from the [latest release](https://github.com/nickdrezza/FineVolume/releases/latest).
2. Unzip it and move `FineVolume.app` to Applications.
3. Open Fine Volume and choose Open Permissions when prompted. Enable Fine
   Volume under Input Monitoring, then return to the app.
4. Choose whether it should launch at login.

Until releases are Developer ID notarized, macOS may require Control-clicking
the app and choosing **Open** the first time.

## Build from source

Fine Volume has no third-party dependencies. Apple's command-line developer
tools are sufficient.

```sh
git clone https://github.com/nickdrezza/FineVolume.git
cd FineVolume
make test
make package
```

The Universal app and ZIP archive are written to `dist/`.

## Architecture

- **AppKit** provides the menu-bar interface and first-launch onboarding.
- **Core Audio** reads and changes the default output device's virtual main
  volume.
- **Core Graphics** monitors only Control modifier-state changes.
- **IOKit HID** temporarily remaps the two physical volume keys while Control
  is held.
- **Carbon Hot Key APIs** register the no-permission Hyper-key arrow fallback.
- **AppKit** displays the lightweight, nonactivating volume HUD.
- **Service Management** controls the optional Launch at Login registration.

More detail is available in [Architecture](docs/ARCHITECTURE.md).

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for
the local workflow and project expectations.

## License

Fine Volume is available under the [MIT License](LICENSE).
