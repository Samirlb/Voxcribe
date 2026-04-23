import SwiftUI

@Observable
@MainActor
final class SettingsViewModel {
    // These are backed by @AppStorage in the view layer
    var targetLanguage: Language = .spanish
    var translationEngine: TranslationEngine = .auto
    var ttsEnabled: Bool = true
    var ttsRate: Float = 0.5
    var showOriginalText: Bool = true
    var showPartialResults: Bool = true
    var conversationMode: Bool = false
    var fontSize: CGFloat = 16
    var silenceTimeout: TimeInterval = 2.0
    var appLanguage: AppLanguage = .system

    var conversationLanguageA: Language = .english
    var conversationLanguageB: Language = .spanish

    static let fontSizeRange: ClosedRange<CGFloat> = 12...28
    static let silenceTimeoutRange: ClosedRange<TimeInterval> = 1.0...5.0
    static let ttsRateRange: ClosedRange<Float> = 0.3...0.7
}
