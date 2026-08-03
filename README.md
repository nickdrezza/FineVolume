# Fine Volume

[![CI](https://github.com/guidrezza/FineVolume/actions/workflows/ci.yml/badge.svg)](https://github.com/guidrezza/FineVolume/actions/workflows/ci.yml)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-black)](https://support.apple.com/macos)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Fine Volume is a tiny, native macOS menu-bar app that changes system volume in
one-percentage-point steps.

## Shortcuts

- `Control + Option + Up Arrow` increases volume by 1%
- `Control + Option + Down Arrow` decreases volume by 1%

The menu-bar speaker icon shows the current volume and lets you disable the
shortcuts or change the Launch at Login setting.

## Why Fine Volume?

The Mac's volume keys use relatively large steps. macOS includes a finer
Option-Shift shortcut, but Fine Volume provides predictable 1% adjustments with
a memorable global shortcut.

Fine Volume registers two ordinary global hotkeys instead of intercepting every
keyboard event. This keeps the app small and avoids sensitive privacy access.

## Permissions

Fine Volume requires **no macOS privacy permissions**:

- No Accessibility permission
- No Input Monitoring permission
- No microphone or audio-recording permission
- No Screen Recording permission
- No network access

Core Audio changes the current output device's volume directly. The optional
Launch at Login feature is registered through Apple's Service Management API
and remains visible and controllable in System Settings → General → Login Items.

On first launch, Fine Volume explains its shortcuts and privacy behavior, then
asks whether it should launch at login. It never enables that setting without
the user's choice.

Read the complete [privacy statement](PRIVACY.md).

## Requirements

- macOS 13 Ventura or later
- Apple Silicon or Intel Mac
- An output device with software-controllable system volume

Some HDMI, USB, aggregate, and professional audio devices do not expose a
settable system volume. Fine Volume reports that limitation in its menu instead
of silently failing.

## Install

1. Download `FineVolume.zip` from the [latest release](https://github.com/guidrezza/FineVolume/releases/latest).
2. Unzip it and move `FineVolume.app` to Applications.
3. Open Fine Volume.
4. Choose whether it should launch at login.

Until releases are Developer ID notarized, macOS may require Control-clicking
the app and choosing **Open** the first time.

## Build from source

Fine Volume has no third-party dependencies. Apple's command-line developer
tools are sufficient.

```sh
git clone https://github.com/guidrezza/FineVolume.git
cd FineVolume
make test
make package
```

The Universal app and ZIP archive are written to `dist/`.

## Architecture

- **AppKit** provides the menu-bar interface and first-launch onboarding.
- **Core Audio** reads and changes the default output device's virtual main
  volume.
- **Carbon Hot Key APIs** register only the two explicit global shortcuts.
- **Service Management** controls the optional Launch at Login registration.

More detail is available in [Architecture](docs/ARCHITECTURE.md).

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for
the local workflow and project expectations.

## License

Fine Volume is available under the [MIT License](LICENSE).
