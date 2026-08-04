# Contributing

Thanks for helping improve Fine Volume.

## Development setup

Requirements:

- macOS 13 or later
- Apple command-line developer tools or Xcode
- Swift 6 toolchain

Run the checks and build the app:

```sh
make test
swift build
```

Create a local Universal app bundle:

```sh
make package
```

For a manual shortcut check, open the generated `dist/FineVolume.app`, grant
Fine Volume access under Input Monitoring, then verify that
Control + Volume Up or Down moves the menu's displayed level by exactly 1% and
briefly displays the volume HUD. Verify that unmodified volume keys retain
macOS's normal behavior. Also verify the Hyper-key arrow fallback on a clean
machine without those permissions.

## Pull requests

1. Keep changes focused on Fine Volume's small, native scope.
2. Add or update checks for pure volume behavior.
3. Run `make test` and `make package` before opening the pull request.
4. Explain user-visible behavior and any permission or privacy impact.
5. Do not add analytics, networking, or third-party dependencies without prior
   discussion in an issue.

## Reporting bugs

Include your macOS version, Mac architecture, output device, exact steps, and
whether the menu shows an error. Do not include private system logs without
reviewing them first.
