# Fine Volume

Fine Volume is a tiny, open-source macOS menu-bar app that changes the system
volume in one-percentage-point steps.

Press:

- `Control + Option + Up Arrow` to increase volume by 1%
- `Control + Option + Down Arrow` to decrease volume by 1%

## Why this shortcut?

Fine Volume uses ordinary global hotkeys instead of intercepting the Mac's
media keys. That keeps the app lightweight and avoids Input Monitoring and
Accessibility permissions.

## Requirements

- macOS 13 Ventura or later
- An output device with a software-controllable system volume

Some HDMI, USB, aggregate, and professional audio devices do not expose a
settable system volume. Fine Volume reports that limitation in its menu.

## Install

Download `FineVolume.zip`, unzip it, and move `FineVolume.app` to Applications.

Unsigned development builds may require Control-clicking the app and choosing
Open the first time. Official releases should be signed and notarized.

## Build

The project has no third-party dependencies. Apple's command-line developer
tools are sufficient.

```sh
make test
make package
```

The packaged app and ZIP archive are written to `dist/`.

## Privacy

Fine Volume does not capture audio, monitor keystrokes, connect to the network,
or collect analytics. The two shortcuts are registered directly with macOS.

## License

MIT
