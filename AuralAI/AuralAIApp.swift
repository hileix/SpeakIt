//
//  AuralAIApp.swift
//  AuralAI
//
//  Created by mac on 2026/3/21.
//

import SwiftUI

@main
struct AuralAIApp: App {
    let persistenceController = PersistenceController.shared

    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    var body: some Scene {
        #if os(macOS)
        MenuBarExtra("AuralAI", systemImage: "speaker.wave.2.fill") {
            Button("Settings") {
                appDelegate.openSettingsFromMenuBar()
            }

            Divider()

            Button("Exit") {
                appDelegate.quitFromMenuBar()
            }
        }
        #else
        // iOS: Standard window-based app
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        #endif
    }
}

#if os(macOS)
/// App delegate for handling macOS-specific functionality
class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindow: NSWindow?

    private let hotkeyService = GlobalHotkeyService.shared
    private let clipboardMonitor = ClipboardMonitor.shared
    private let ttsService = TTSService.shared
    private let settings = SpeechSettings.shared
    private let persistenceController = PersistenceController.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 AuralAI applicationDidFinishLaunching")
        observeSettings()
        setupHotkeyHandler()
        checkAccessibilityPermissions()

        DispatchQueue.main.async {
            self.openSettings()
        }

        print("✅ AuralAI started. Press \(settings.hotkeyDisplayString) to speak selected text.")
    }

    /// Setup global hotkey handler
    private func setupHotkeyHandler() {
        hotkeyService.onHotkeyTriggered = { [weak self] in
            self?.handleGlobalHotkey()
        }
    }

    /// Check and request accessibility permissions
    private func checkAccessibilityPermissions() {
        if !hotkeyService.hasAccessibilityPermissions() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.hotkeyService.requestAccessibilityPermissions()
            }
        }
    }

    /// Handle global hotkey press
    @objc private func handleGlobalHotkey() {
        print("\(settings.hotkeyDisplayString) pressed - capturing selected text")

        // Step 1: Simulate Cmd+C to copy selected text
        hotkeyService.copySelectedText()

        // Step 2: Wait a bit for clipboard to update, then read and speak
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let text = self.clipboardMonitor.readClipboardText(), !text.isEmpty {
                print("✅ Text captured from clipboard: \(text.prefix(50))...")
                print("📢 Starting speech synthesis...")

                // Speak the text
                self.ttsService.speak(text: text, settings: self.settings)

                // Save to history
                self.saveSpeechHistory(text: text, source: "hotkey")
            } else {
                print("❌ No text found in clipboard")
            }
        }
    }

    /// Open settings window
    @objc private func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView(onDone: { [weak self] in
                self?.settingsWindow?.close()
            })
                .frame(width: 500, height: 600)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)

            let hostingController = NSHostingController(rootView: settingsView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "AuralAI Settings"
            window.styleMask = [.titled, .closable, .resizable]
            window.setContentSize(NSSize(width: 500, height: 600))
            window.center()
            window.isReleasedWhenClosed = false

            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Quit application
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    /// Save speech history to CoreData
    private func saveSpeechHistory(text: String, source: String) {
        persistenceController.saveSpeechHistory(
            text: text,
            source: source,
            voice: settings.currentVoice.identifier,
            duration: 0.0
        )
    }

    private func observeSettings() {}

    func openSettingsFromMenuBar() {
        openSettings()
    }

    func quitFromMenuBar() {
        quitApp()
    }
}
#endif
