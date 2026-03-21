//
//  SettingsView.swift
//  SpeakIt
//
//  Created by SpeakIt Migration
//

import SwiftUI
import AVFoundation

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SpeechSettings.shared
    @StateObject private var ttsService = TTSService.shared

    @State private var testText = "This is a test of the speech settings."
    @State private var hotkeyInput = SpeechSettings.shared.hotkeyKey

    let onDone: (() -> Void)?

    init(onDone: (() -> Void)? = nil) {
        self.onDone = onDone
    }

    var body: some View {
        #if os(macOS)
        macOSContent
        #else
        NavigationView {
            settingsForm
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            closeView()
                        }
                    }
                }
        }
        #endif
    }

    private func testSpeech() {
        ttsService.speak(text: testText, settings: settings)
    }

    private func closeView() {
        if let onDone {
            onDone()
        } else {
            dismiss()
        }
    }

    private func modifierBinding(_ modifier: SpeechSettings.HotkeyModifier) -> Binding<Bool> {
        Binding(
            get: { settings.isModifierEnabled(modifier) },
            set: { settings.setModifier(modifier, enabled: $0) }
        )
    }

    private var settingsForm: some View {
        Form {
            Section("Shortcut") {
                TextField("Shortcut Key", text: $hotkeyInput)
                    .onChange(of: hotkeyInput) { newValue in
                        let normalized = String(newValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased().prefix(1))
                        hotkeyInput = normalized
                        settings.hotkeyKey = normalized.isEmpty ? "S" : normalized
                    }

                Toggle("Control", isOn: modifierBinding(.control))
                Toggle("Option", isOn: modifierBinding(.option))
                Toggle("Command", isOn: modifierBinding(.command))
                Toggle("Shift", isOn: modifierBinding(.shift))

                HStack {
                    Text("Current Shortcut")
                    Spacer()
                    Text(settings.hotkeyDisplayString)
                        .foregroundColor(.secondary)
                }

                Text("Choose one key and at least one modifier for the global shortcut.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Section("Voice") {
                Picker("Voice", selection: $settings.voiceIdentifier) {
                    Text("Default").tag(nil as String?)
                    ForEach(SpeechSettings.allVoices(), id: \.identifier) { voice in
                        Text("\(voice.name) (\(voice.language))")
                            .tag(voice.identifier as String?)
                    }
                }

                Text("Select the voice for text-to-speech")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Section("Speech Rate") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Rate")
                        Spacer()
                        Text(String(format: "%.2f", settings.rate))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.rate, in: AVSpeechUtteranceMinimumSpeechRate...AVSpeechUtteranceMaximumSpeechRate)
                    Text("Adjust the speed of speech (slower ← → faster)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            Section("Speech Pitch") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Pitch")
                        Spacer()
                        Text(String(format: "%.2f", settings.pitch))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.pitch, in: 0.5...2.0)
                    Text("Adjust the pitch of speech (lower ← → higher)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            Section("Clipboard") {
                Toggle("Auto-speak Clipboard", isOn: $settings.autoSpeakClipboard)
                Text("Automatically speak text when copied to clipboard and app is opened")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Section {
                Button(action: testSpeech) {
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                        Text("Test Speech")
                    }
                    .frame(maxWidth: .infinity)
                }

                Button(action: {
                    settings.resetToDefaults()
                    hotkeyInput = settings.hotkeyKey
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset to Defaults")
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    #if os(macOS)
    private var macOSContent: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Done") {
                    closeView()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)

            Divider()

            settingsForm
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    #endif
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
