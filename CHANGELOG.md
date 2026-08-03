# Changelog

All notable changes to Fine Volume are documented here.

## 0.2.0 — 2026-08-03

- Replaced the conflicting arrow-key shortcut with Control-Option-Volume Up and
  Control-Option-Volume Down.
- Suppress macOS's normal volume-key action only for those two combinations, so
  each matching press changes volume by 1%.
- Added first-launch Accessibility and Input Monitoring permission onboarding.
- Restored the separate first-launch Launch at Login choice.

## 0.1.0 — 2026-08-02

- Added 1% system-volume adjustments with Control-Option-Up and
  Control-Option-Down.
- Added a native menu-bar interface with current-volume display.
- Added first-launch onboarding and an optional Launch at Login setting.
- Added graceful handling for output devices without software volume control.
- Added Universal Apple Silicon and Intel packaging.
