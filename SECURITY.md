# Security Policy

## Supported versions

Security fixes are applied to the latest release and the `main` branch.

## Reporting a vulnerability

Please use GitHub's private vulnerability reporting feature for this repository
instead of opening a public issue. Include reproduction steps, affected macOS
versions, and the expected impact.

Fine Volume intentionally avoids network access, audio capture, and third-party
dependencies to keep its security surface small. It uses a narrowly scoped
event tap only for Control-Option Volume Up and Volume Down after the user has
granted macOS Accessibility and Input Monitoring access.
