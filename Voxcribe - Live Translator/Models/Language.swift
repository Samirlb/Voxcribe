import Foundation
import NaturalLanguage

enum Language: String, CaseIterable, Identifiable, Codable, Sendable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case chineseSimplified = "zh-Hans"
    case japanese = "ja"
    case korean = "ko"
    case russian = "ru"
    case arabic = "ar"
    case hindi = "hi"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: "English"
        case .spanish: "Español"
        case .french: "Français"
        case .german: "Deutsch"
        case .italian: "Italiano"
        case .portuguese: "Português"
        case .chineseSimplified: "中文"
        case .japanese: "日本語"
        case .korean: "한국어"
        case .russian: "Русский"
        case .arabic: "العربية"
        case .hindi: "हिन्दी"
        }
    }

    var speechLocaleIdentifier: String {
        switch self {
        case .english: "en-US"
        case .spanish: "es-ES"
        case .french: "fr-FR"
        case .german: "de-DE"
        case .italian: "it-IT"
        case .portuguese: "pt-BR"
        case .chineseSimplified: "zh-CN"
        case .japanese: "ja-JP"
        case .korean: "ko-KR"
        case .russian: "ru-RU"
        case .arabic: "ar-SA"
        case .hindi: "hi-IN"
        }
    }

    var locale: Locale {
        Locale(identifier: speechLocaleIdentifier)
    }

    var nlLanguage: NLLanguage {
        switch self {
        case .english: .english
        case .spanish: .spanish
        case .french: .french
        case .german: .german
        case .italian: .italian
        case .portuguese: .portuguese
        case .chineseSimplified: .simplifiedChinese
        case .japanese: .japanese
        case .korean: .korean
        case .russian: .russian
        case .arabic: .arabic
        case .hindi: .hindi
        }
    }

    var ttsVoiceLanguage: String {
        switch self {
        case .chineseSimplified: "zh-CN"
        default: rawValue
        }
    }

    var translationLocaleLanguage: Locale.Language {
        switch self {
        case .chineseSimplified: Locale.Language(identifier: "zh-Hans")
        default: Locale.Language(identifier: rawValue)
        }
    }

    static func from(nlLanguage: NLLanguage) -> Language? {
        allCases.first { $0.nlLanguage == nlLanguage }
    }

    static func from(localeIdentifier: String) -> Language? {
        let normalized = localeIdentifier.lowercased().replacingOccurrences(of: "_", with: "-")
        if let exact = allCases.first(where: { normalized.hasPrefix($0.rawValue.lowercased()) }) {
            return exact
        }
        let prefix = String(normalized.prefix(2))
        return allCases.first { $0.rawValue.hasPrefix(prefix) }
    }
}
