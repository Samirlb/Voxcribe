import SwiftUI

@main
struct VoxcribeApp: App {
    var body: some Scene {
        WindowGroup {
            TranscriptionView()
        }
        #if os(macOS)
        .defaultSize(width: 500, height: 700)
        #endif

        #if os(macOS)
        MenuBarExtra("Voxcribe", systemImage: "waveform.circle") {
            Button("Show Window") {
                NSApplication.shared.activate(ignoringOtherApps: true)
                if let window = NSApplication.shared.windows.first {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            .keyboardShortcut("v", modifiers: [.command, .shift])

            Divider()

            Button("Quit Voxcribe") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        #endif
    }
}
