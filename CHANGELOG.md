# Changelog

All notable changes to Fine Volume are documented here.

## Unreleased

- Show only the up/down shortcuts, Open at Login, and Quit in the menu.
- Show the volume-key mapping when available, or the arrow fallback otherwise.
- Remove the shortcut enable switch and the separate login prompt.
- Move the current volume and errors to the speaker tooltip. Keep the volume HUD.
- Shorten the one-time permission prompt.

## 0.5.0 — 2026-08-04

- Replaced unsupported system-defined-event interception with Apple's public
  HID key-remapping API.
- Volume Up/Down are remapped to private function keys only while Control is
  held; unmodified volume keys remain entirely native.
- Reduced the required privacy access to Input Monitoring only.
- Preserve existing user key mappings and restore them immediately when
  Control is released, shortcuts are disabled, or the app quits.
- Added a reproducible tag-based GitHub release workflow and documented the
  release process.

## 0.4.0 — 2026-08-04

- Restored the requested Control + Volume Up/Down shortcut using a narrowly
  filtered media-key event tap.
- Added explicit Accessibility and Input Monitoring setup with live status in
  the menu-bar menu.
- Kept the Hyper-key arrow shortcut as a no-permission fallback.
- Added the volume HUD to both shortcut paths.

## 0.3.0 — 2026-08-03

- Replaced media-key interception with Control-Option-Command-Shift plus Up or
  Down Arrow global hotkeys for compatibility with macOS 27 and to avoid common
  window-manager bindings.
- Removed the Accessibility and Input Monitoring permission requirement.
- Added a temporary volume HUD with the exact percentage and a progress bar.

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
