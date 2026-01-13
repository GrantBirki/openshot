# v0 Specification

This document outlines the specifications for version 0 (v0) of the OpenShot macOS screenshot utility.

## Goals

- Keep the app simple, reliable, and installable via Homebrew (open source, unsigned is acceptable for MVP).
- Minimum macOS: 11 (Big Sur) to cover Apple Silicon devices broadly.
- Build as a macOS app bundle, unsigned for MVP.
- Distribute via Homebrew cask.
- Users will need to approve the app on first run (Gatekeeper).
- Provide an extemely simple and easy to use screenshot utility that works in a similar way to the built-in macOS screenshot tool.
- Extend the MacOS screenshot tool with additional features such as:
  - Custom delays or even disabling the post-capture overlay image preview/hover tile.
  - Custom save locations including the ability to automatically save to clipboard, desktop, documents, or a user specified folder.
  - Custom file naming conventions.
  - The ability to fully disable the floating thumbnail preview and just default to instantly saving the screenshot or copying to clipboard.
  - Makes use of macOS native screenshot APIs where possible to ensure compatibility and reliability.
  - The ability to "click and drag" the resulting screenshot that hovers in the bottom right corner to drag and drop it into other applications.
  - Support for keyboard shortcuts similar to macOS's built-in screenshot tool. Allow the user to customize these shortcuts so they can choose their own preferred key combinations. This is a global setting that applies system-wide for taking screenshots.
  - It should be lightweight and have minimal impact on system resources.
  - It should have a clean and intuitive user interface that is easy to navigate.
  - It should be stable and reliable, with minimal bugs or crashes.
  - It should be secure and respect user privacy.
  - It should have the ability to do click-and-drag after pressing the screenshot shortcut to immediately select the area to capture.
  - It should support capturing screenshots of specific windows, full screen, or selected areas.
  - By default, it should save screenshots as a maximum quality PNG file to preserve image quality.
  - By default, filenames of screenshots should be named in the following format: `screenshot_<rfc3339_timestamp>.png`. The timestamp should be like `2026-01-12T13:43:15-08:00` so it has ease of use in the user's local timezone and is sortable.

## Non-Goals (MVP)

- No custom installer; Homebrew cask only.
