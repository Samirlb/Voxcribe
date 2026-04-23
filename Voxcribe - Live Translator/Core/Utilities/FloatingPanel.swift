#if os(macOS)
import SwiftUI
import AppKit

struct FloatingPanelKey: EnvironmentKey {
    static let defaultValue: FloatingPanel? = nil
}

extension EnvironmentValues {
    var floatingPanel: FloatingPanel? {
        get { self[FloatingPanelKey.self] }
        set { self[FloatingPanelKey.self] = newValue }
    }
}

final class FloatingPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView, .hudWindow],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        animationBehavior = .utilityWindow

        backgroundColor = .clear
        isOpaque = false
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func toggle() {
        if isVisible {
            orderOut(nil)
        } else {
            orderFront(nil)
        }
    }
}
#endif
