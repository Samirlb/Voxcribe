import SwiftUI

enum VoxcribeTokens {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let pill: CGFloat = 100
    }

    enum FontSize {
        static let caption: CGFloat = 12
        static let body: CGFloat = 16
        static let title: CGFloat = 20
        static let largeTitle: CGFloat = 28
    }

    enum Colors {
        static let accent = Color.accentColor
        static let speakerA = Color.blue
        static let speakerB = Color.green
        static let recording = Color.red
        static let partialText = Color.secondary
        static let finalText = Color.primary
        static let translatedText = Color.accentColor
        static let background = Color.white
        static let secondaryBackground = Color.secondary

        #if os(macOS)
        static let floatingBackground = Color(.windowBackgroundColor).opacity(0.95)
        #endif
    }

    enum Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let smooth = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.8)
    }
}
