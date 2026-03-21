//
//  SpeechSettings.swift
//  SpeakIt
//
//  Created by SpeakIt Migration
//

import Foundation
import AVFoundation

/// Speech settings model with UserDefaults persistence
class SpeechSettings: ObservableObject {
    static let shared = SpeechSettings()

    struct HotkeyModifier: OptionSet {
        let rawValue: Int

        static let control = HotkeyModifier(rawValue: 1 << 0)
        static let option = HotkeyModifier(rawValue: 1 << 1)
        static let command = HotkeyModifier(rawValue: 1 << 2)
        static let shift = HotkeyModifier(rawValue: 1 << 3)

        static let `default`: HotkeyModifier = [.control]
    }

    // App Group identifier for sharing between app and extension
    private static let appGroupIdentifier = "group.com.yourteam.speakit"
    private let defaults: UserDefaults

    // Keys for UserDefaults
    private enum Keys {
        static let voiceIdentifier = "voiceIdentifier"
        static let rate = "rate"
        static let pitch = "pitch"
        static let autoSpeakClipboard = "autoSpeakClipboard"
        static let hotkeyKey = "hotkeyKey"
        static let hotkeyModifiers = "hotkeyModifiers"
    }

    // MARK: - Published Properties

    @Published var voiceIdentifier: String? {
        didSet {
            defaults.set(voiceIdentifier, forKey: Keys.voiceIdentifier)
        }
    }

    @Published var rate: Float {
        didSet {
            defaults.set(rate, forKey: Keys.rate)
        }
    }

    @Published var pitch: Float {
        didSet {
            defaults.set(pitch, forKey: Keys.pitch)
        }
    }

    @Published var autoSpeakClipboard: Bool {
        didSet {
            defaults.set(autoSpeakClipboard, forKey: Keys.autoSpeakClipboard)
        }
    }

    @Published var hotkeyKey: String {
        didSet {
            let normalized = SpeechSettings.normalizedHotkeyKey(from: hotkeyKey)
            if hotkeyKey != normalized {
                hotkeyKey = normalized
                return
            }
            defaults.set(hotkeyKey, forKey: Keys.hotkeyKey)
        }
    }

    @Published var hotkeyModifiersRawValue: Int {
        didSet {
            defaults.set(hotkeyModifiersRawValue, forKey: Keys.hotkeyModifiers)
        }
    }

    // MARK: - Initialization

    private init() {
        // Use App Group defaults for sharing with Share Extension
        if let appGroupDefaults = UserDefaults(suiteName: SpeechSettings.appGroupIdentifier) {
            self.defaults = appGroupDefaults
        } else {
            // Fallback to standard defaults
            self.defaults = UserDefaults.standard
            print("Warning: Could not initialize App Group defaults. Using standard UserDefaults.")
        }

        // Load saved settings or use defaults
        self.voiceIdentifier = defaults.string(forKey: Keys.voiceIdentifier)
        self.rate = defaults.object(forKey: Keys.rate) as? Float ?? AVSpeechUtteranceDefaultSpeechRate
        self.pitch = defaults.object(forKey: Keys.pitch) as? Float ?? 1.0
        self.autoSpeakClipboard = defaults.bool(forKey: Keys.autoSpeakClipboard)
        self.hotkeyKey = SpeechSettings.normalizedHotkeyKey(from: defaults.string(forKey: Keys.hotkeyKey) ?? "S")

        let storedModifiers = defaults.object(forKey: Keys.hotkeyModifiers) as? Int
        self.hotkeyModifiersRawValue = storedModifiers ?? HotkeyModifier.default.rawValue
    }

    // MARK: - Helper Methods

    /// Get the current voice or default system voice
    var currentVoice: AVSpeechSynthesisVoice {
        if let identifier = voiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            return voice
        }
        return AVSpeechSynthesisVoice(language: "en-US") ?? AVSpeechSynthesisVoice()
    }

    /// Reset all settings to defaults
    func resetToDefaults() {
        voiceIdentifier = nil
        rate = AVSpeechUtteranceDefaultSpeechRate
        pitch = 1.0
        autoSpeakClipboard = false
        hotkeyKey = "S"
        hotkeyModifiers = .default
    }

    /// Get all available voices grouped by language
    static func availableVoices() -> [String: [AVSpeechSynthesisVoice]] {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        return Dictionary(grouping: voices) { voice in
            voice.language
        }
    }

    /// Get all available voices as a flat array
    static func allVoices() -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices()
    }

    var hotkeyModifiers: HotkeyModifier {
        get { HotkeyModifier(rawValue: hotkeyModifiersRawValue) }
        set { hotkeyModifiersRawValue = newValue.rawValue }
    }

    var hotkeyDisplayString: String {
        let modifierNames: [(HotkeyModifier, String)] = [
            (.control, "Ctrl"),
            (.option, "Option"),
            (.command, "Cmd"),
            (.shift, "Shift")
        ]

        let parts = modifierNames.compactMap { modifier, name in
            hotkeyModifiers.contains(modifier) ? name : nil
        }

        let key = hotkeyKey.isEmpty ? "?" : hotkeyKey.uppercased()
        return (parts + [key]).joined(separator: "+")
    }

    var supportsGlobalHotkey: Bool {
        SpeechSettings.keyCode(for: hotkeyKey) != nil && !hotkeyModifiers.isEmpty
    }

    func setModifier(_ modifier: HotkeyModifier, enabled: Bool) {
        var updated = hotkeyModifiers
        if enabled {
            updated.insert(modifier)
        } else {
            updated.remove(modifier)
        }
        hotkeyModifiers = updated
    }

    func isModifierEnabled(_ modifier: HotkeyModifier) -> Bool {
        hotkeyModifiers.contains(modifier)
    }

    static func keyCode(for key: String) -> UInt32? {
        keyCodeMap[normalizedHotkeyKey(from: key)]
    }

    private static func normalizedHotkeyKey(from key: String) -> String {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard let first = trimmed.first else { return "S" }
        return String(first)
    }

    private static let keyCodeMap: [String: UInt32] = [
        "A": 0, "S": 1, "D": 2, "F": 3, "H": 4, "G": 5, "Z": 6, "X": 7, "C": 8,
        "V": 9, "B": 11, "Q": 12, "W": 13, "E": 14, "R": 15, "Y": 16, "T": 17,
        "1": 18, "2": 19, "3": 20, "4": 21, "6": 22, "5": 23, "=": 24, "9": 25,
        "7": 26, "-": 27, "8": 28, "0": 29, "]": 30, "O": 31, "U": 32, "[": 33,
        "I": 34, "P": 35, "L": 37, "J": 38, "'": 39, "K": 40, ";": 41, "\\": 42,
        ",": 43, "/": 44, "N": 45, "M": 46, ".": 47
    ]
}

// MARK: - Codable Support for Serialization
extension SpeechSettings {
    struct CodableSettings: Codable {
        let voiceIdentifier: String?
        let rate: Float
        let pitch: Float
        let autoSpeakClipboard: Bool
        let hotkeyKey: String
        let hotkeyModifiers: Int
    }

    var codable: CodableSettings {
        CodableSettings(
            voiceIdentifier: voiceIdentifier,
            rate: rate,
            pitch: pitch,
            autoSpeakClipboard: autoSpeakClipboard,
            hotkeyKey: hotkeyKey,
            hotkeyModifiers: hotkeyModifiers.rawValue
        )
    }

    func update(from codable: CodableSettings) {
        voiceIdentifier = codable.voiceIdentifier
        rate = codable.rate
        pitch = codable.pitch
        autoSpeakClipboard = codable.autoSpeakClipboard
        hotkeyKey = codable.hotkeyKey
        hotkeyModifiers = HotkeyModifier(rawValue: codable.hotkeyModifiers)
    }
}
