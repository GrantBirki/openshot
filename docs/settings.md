# Settings

This document describes the settings available in OneShot.

## General

- `Launch at login`: Start OneShot automatically when you sign in.

## Output

- `Filename prefix`: Prefix used when naming saved screenshots.
- `Save location`: Choose where screenshots are saved (`Downloads`, `Desktop`, `Documents`, or `Custom`).
- `Custom folder`: Path used when `Save location` is set to `Custom`.

## Preview

- `Show floating preview`: Show the thumbnail preview after capture.
- `Auto-dismiss preview`: Automatically dismiss the preview after the save delay.
- `Save delay (seconds)`: Time to wait before saving a screenshot when previews are enabled.
- `On new screenshot`: Behavior when another capture happens while a preview is still visible.
  - `Save previous capture`: Saves the existing capture immediately and replaces the preview.
  - `Discard previous capture`: Cancels the existing capture and replaces the preview.

When previews are disabled, screenshots are saved immediately and the save delay is ignored.

## Screenshot Shortcuts

- `Use OneShot screenshot shortcuts`: Register `Command+Shift+3/4/5` while OneShot is running.
- `Full screen`: `Command+Shift+3`.
- `Selection`: `Command+Shift+4` (press Space to switch to window capture).
- `Capture toolbar`: `Command+Shift+5`.

If macOS shortcuts are enabled, OneShot may not be able to register these keys.

## Enable Shortcuts

- Open System Settings > Keyboard > Keyboard Shortcuts > Screenshots.
- Disable the save/copy shortcuts for the screen and selected area.
