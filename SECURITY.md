# Security Policy

## Supported versions

Security fixes are applied to the latest release and the `main` branch.

## Reporting a vulnerability

Please use GitHub's private vulnerability reporting feature for this repository
instead of opening a public issue. Include reproduction steps, affected macOS
versions, and the expected impact.

Fine Volume intentionally avoids network access, audio capture, and
third-party dependencies to keep its security surface small. With explicit
user permission, its event tap monitors only modifier-state changes. Apple's
public HID API temporarily remaps the volume usages while Control is held; its
fallback uses two explicit global hot keys.
