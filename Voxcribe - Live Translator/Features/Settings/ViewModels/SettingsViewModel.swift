import SwiftUI

@Observable
@MainActor
final class SettingsViewModel {
    private static let defaults = UserDefaults.standard

    // MARK: - Persisted Settings

    var sourceLanguage: Language {
        didSet { Self.defaults.set(sourceLanguage.rawValue, forKey: "sourceLanguage") }
    }
    var targetLanguage: Language {
        didSet { Self.defaults.set(targetLanguage.rawValue, forKey: "targetLanguage") }
    }
    var translationEngine: TranslationEngine {
        didSet { Self.defaults.set(translationEngine.rawValue, forKey: "translationEngine") }
    }
    var ttsEnabled: Bool {
        didSet { Self.defaults.set(ttsEnabled, forKey: "ttsEnabled") }
    }
    var ttsRate: Float {
        didSet { Self.defaults.set(ttsRate, forKey: "ttsRate") }
    }
    var showOriginalText: Bool {
        didSet { Self.defaults.set(showOriginalText, forKey: "showOriginalText") }
    }
    var showPartialResults: Bool {
        didSet { Self.defaults.set(showPartialResults, forKey: "showPartialResults") }
    }
    var conversationMode: Bool {
        didSet { Self.defaults.set(conversationMode, forKey: "conversationMode") }
    }
    var fontSize: CGFloat {
        didSet { Self.defaults.set(Double(fontSize), forKey: "fontSize") }
    }
    var silenceTimeout: TimeInterval {
        didSet { Self.defaults.set(silenceTimeout, forKey: "silenceTimeout") }
    }
    var appLanguage: AppLanguage {
        didSet { Self.defaults.set(appLanguage.rawValue, forKey: "appLanguage") }
    }
    var conversationLanguageA: Language {
        didSet { Self.defaults.set(conversationLanguageA.rawValue, forKey: "conversationLanguageA") }
    }
    var conversationLanguageB: Language {
        didSet { Self.defaults.set(conversationLanguageB.rawValue, forKey: "conversationLanguageB") }
    }
    var audioSource: AudioSource {
        didSet { Self.defaults.set(audioSource.rawValue, forKey: "audioSource") }
    }

    static let fontSizeRange: ClosedRange<CGFloat> = 12...28
    static let silenceTimeoutRange: ClosedRange<TimeInterval> = 1.0...5.0
    static let ttsRateRange: ClosedRange<Float> = 0.3...0.7

    init() {
        let d = Self.defaults
        sourceLanguage = Language(rawValue: d.string(forKey: "sourceLanguage") ?? "") ?? .english
        targetLanguage = Language(rawValue: d.string(forKey: "targetLanguage") ?? "") ?? .spanish
        translationEngine = TranslationEngine(rawValue: d.string(forKey: "translationEngine") ?? "") ?? .auto
        ttsEnabled = d.object(forKey: "ttsEnabled") == nil ? true : d.bool(forKey: "ttsEnabled")
        ttsRate = d.object(forKey: "ttsRate") == nil ? 0.5 : d.float(forKey: "ttsRate")
        showOriginalText = d.object(forKey: "showOriginalText") == nil ? true : d.bool(forKey: "showOriginalText")
        showPartialResults = d.object(forKey: "showPartialResults") == nil ? true : d.bool(forKey: "showPartialResults")
        conversationMode = d.bool(forKey: "conversationMode")
        fontSize = d.object(forKey: "fontSize") == nil ? 16 : CGFloat(d.double(forKey: "fontSize"))
        silenceTimeout = d.object(forKey: "silenceTimeout") == nil ? 2.0 : d.double(forKey: "silenceTimeout")
        appLanguage = AppLanguage(rawValue: d.string(forKey: "appLanguage") ?? "") ?? .system
        conversationLanguageA = Language(rawValue: d.string(forKey: "conversationLanguageA") ?? "") ?? .english
        conversationLanguageB = Language(rawValue: d.string(forKey: "conversationLanguageB") ?? "") ?? .spanish
        audioSource = AudioSource(rawValue: d.string(forKey: "audioSource") ?? "") ?? .microphone
    }
}
