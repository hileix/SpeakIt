# AuralAI

AuralAI is a SwiftUI text-to-speech app built on top of AVFoundation.

It runs as a macOS menu bar app and reads the current selection with a global hotkey.

## Current Features

- Global hotkey on macOS for reading selected text
- Customizable shortcut key and modifier combination
- English voice selection with live preview
- Adjustable speech rate and pitch
- Settings UI in English and Chinese
- Explicit save flow in settings
- Speech history stored with Core Data

## macOS Flow

AuralAI on macOS is a `MenuBarExtra` app.

1. Launch the app.
2. Open `Settings` from the menu bar.
3. Choose the shortcut, language, voice, rate, and pitch.
4. Click `Save` to persist changes.
5. Select text in any app.
6. Press the configured hotkey.

When the hotkey is pressed, AuralAI simulates `Cmd+C`, reads the copied text from the pasteboard, and speaks it aloud.

The app requires Accessibility permission on macOS so it can:

- register a global hotkey
- simulate `Cmd+C` to capture selected text

## Settings

The settings window currently supports:

- one-key shortcut input plus a modifier-combination picker
- English or Chinese UI language
- English voice selection
- default voice fallback that prefers higher-quality English voices
- speech rate and pitch controls
- a `Test Speech` preview button
- a `Reset to Defaults` action

Changes in the settings window are edited as a draft and are only applied after clicking `Save`. Saving does not close the window.

## Data Storage

Speech settings are stored in `UserDefaults`, using the app group suite when available:

- app group: `group.com.yourteam.speakit`
- keys: `voiceIdentifier`, `rate`, `pitch`, `language`, `hotkeyKey`, `hotkeyModifiers`

Speech history is stored in Core Data.

## Project Structure

- `AuralAI/`: app source
- `AuralAI/Models/`: settings and model types
- `AuralAI/Services/`: hotkey, clipboard, and TTS services
- `AuralAI/Views/`: SwiftUI views
- `AuralAITests/`: unit tests
- `AuralAIUITests/`: UI tests

## Requirements

- Xcode
- macOS for the menu bar hotkey workflow
- Apple signing configured in Xcode if you want to build and run directly from the project

## Build

Open `AuralAI.xcodeproj` in Xcode and run the `AuralAI` scheme.

If Xcode reports a signing error, update the team and signing certificate in the project settings before building.

## DMG Packaging

To build a distributable macOS app bundle and package it into a DMG:

```bash
bash Scripts/package_dmg.sh --clean
```

By default the script uses `xcodebuild archive`, copies the archived `AuralAI.app` into `dist/`, and creates `dist/AuralAI.dmg`.
The generated DMG includes a standard drag-to-install layout with `AuralAI.app` and an `Applications` shortcut.

Useful variants:

```bash
bash Scripts/package_dmg.sh --mode build
bash Scripts/package_dmg.sh --configuration Debug --build-dir out
```

If signing is not configured correctly in Xcode, the script will fail during the `xcodebuild` step.
If Finder automation is blocked by system permissions, the script still creates a usable drag-install DMG, but the icon layout may fall back to the default arrangement.

## License

This project is licensed under the MIT License. See `LICENSE` for details.
