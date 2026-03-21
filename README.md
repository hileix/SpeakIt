# SpeakIt

SpeakIt is a small Apple-platform text-to-speech app built with SwiftUI and AVFoundation.

On macOS, it runs as a menu bar app and can read selected text with a global hotkey. On iOS, it provides a simple window-based interface for entering text and playing speech.

## Features

- Read selected text on macOS with the default global hotkey: `Ctrl+S`
- Speak the current clipboard contents from the menu bar
- Choose voice, speech rate, and pitch
- Save speech history with Core Data
- Simple SwiftUI settings and playback UI

## macOS Behavior

The macOS app runs from the menu bar and works like this:

1. Select text in any app.
2. Press `Ctrl+S`.
3. SpeakIt copies the selection and starts speech playback.

The app requires Accessibility permission on macOS so it can listen for the global hotkey and simulate `Cmd+C` to capture selected text.

## Project Structure

- `SpeakIt/`: app source
- `SpeakIt/Services/`: hotkey, clipboard, and TTS services
- `SpeakIt/Views/`: SwiftUI views
- `SpeakItTests/`: unit tests
- `SpeakItUITests/`: UI tests

## Requirements

- Xcode
- macOS for the menu bar app flow
- An Apple development signing setup if you want to build and run from Xcode

## Build

Open `SpeakIt.xcodeproj` in Xcode and run the `SpeakIt` scheme.

If Xcode reports a signing error, update the team and signing certificate in the project settings before building.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
