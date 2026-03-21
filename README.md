# SpeakIt

SpeakIt is a SwiftUI text-to-speech app built on top of AVFoundation.

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

SpeakIt on macOS is a `MenuBarExtra` app.

1. Launch the app.
2. Open `Settings` from the menu bar.
3. Choose the shortcut, language, voice, rate, and pitch.
4. Click `Save` to persist changes.
5. Select text in any app.
6. Press the configured hotkey.

When the hotkey is pressed, SpeakIt simulates `Cmd+C`, reads the copied text from the pasteboard, and speaks it aloud.

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

- `SpeakIt/`: app source
- `SpeakIt/Models/`: settings and model types
- `SpeakIt/Services/`: hotkey, clipboard, and TTS services
- `SpeakIt/Views/`: SwiftUI views
- `SpeakItTests/`: unit tests
- `SpeakItUITests/`: UI tests

## Requirements

- Xcode
- macOS for the menu bar hotkey workflow
- Apple signing configured in Xcode if you want to build and run directly from the project

## Build

Open `SpeakIt.xcodeproj` in Xcode and run the `SpeakIt` scheme.

If Xcode reports a signing error, update the team and signing certificate in the project settings before building.

## License

This project is licensed under the MIT License. See `LICENSE` for details.
