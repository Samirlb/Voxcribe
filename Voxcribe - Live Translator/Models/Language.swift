import Foundation
import NaturalLanguage

enum Language: String, CaseIterable, Identifiable, Codable, Sendable {
    case english = "en"
    case englishUK = "en-GB"
    case spanish = "es"
    case spanishLatam = "es-419"
    case spanishUS = "es-US"
    case french = "fr"
    case frenchCanada = "fr-CA"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case portugueseBrazil = "pt-BR"
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"
    case japanese = "ja"
    case korean = "ko"
    case russian = "ru"
    case arabic = "ar"
    case hindi = "hi"

    var id: String { rawValue }

    var flag: String {
        switch self {
        case .english:            return "🇺🇸"
        case .englishUK:          return "🇬🇧"
        case .spanish:            return "🇪🇸"
        case .spanishLatam:       return "🇲🇽"
        case .spanishUS:          return "🇺🇸"
        case .french:             return "🇫🇷"
        case .frenchCanada:       return "🇨🇦"
        case .german:             return "🇩🇪"
        case .italian:            return "🇮🇹"
        case .portuguese:         return "🇵🇹"
        case .portugueseBrazil:   return "🇧🇷"
        case .chineseSimplified:  return "🇨🇳"
        case .chineseTraditional: return "🇹🇼"
        case .japanese:           return "🇯🇵"
        case .korean:             return "🇰🇷"
        case .russian:            return "🇷🇺"
        case .arabic:             return "🇸🇦"
        case .hindi:              return "🇮🇳"
        }
    }

    var displayName: String {
        switch self {
        case .english:            return "English"
        case .englishUK:          return "English (UK)"
        case .spanish:            return "Español (España)"
        case .spanishLatam:       return "Español (Latinoamérica)"
        case .spanishUS:          return "Español (EE.UU.)"
        case .french:             return "Français"
        case .frenchCanada:       return "Français (Canada)"
        case .german:             return "Deutsch"
        case .italian:            return "Italiano"
        case .portuguese:         return "Português (Portugal)"
        case .portugueseBrazil:   return "Português (Brasil)"
        case .chineseSimplified:  return "中文 (简体)"
        case .chineseTraditional: return "中文 (繁體)"
        case .japanese:           return "日本語"
        case .korean:             return "한국어"
        case .russian:            return "Русский"
        case .arabic:             return "العربية"
        case .hindi:              return "हिन्दी"
        }
    }

    /// Short label for compact UI (e.g. pickers in control bar)
    var shortName: String {
        switch self {
        case .english:            return "English"
        case .englishUK:          return "English UK"
        case .spanish:            return "Español ES"
        case .spanishLatam:       return "Español LATAM"
        case .spanishUS:          return "Español US"
        case .french:             return "Français"
        case .frenchCanada:       return "Français CA"
        case .german:             return "Deutsch"
        case .italian:            return "Italiano"
        case .portuguese:         return "Português PT"
        case .portugueseBrazil:   return "Português BR"
        case .chineseSimplified:  return "中文 简体"
        case .chineseTraditional: return "中文 繁體"
        case .japanese:           return "日本語"
        case .korean:             return "한국어"
        case .russian:            return "Русский"
        case .arabic:             return "العربية"
        case .hindi:              return "हिन्दी"
        }
    }

    var speechLocaleIdentifier: String {
        switch self {
        case .english:            return "en-US"
        case .englishUK:          return "en-GB"
        case .spanish:            return "es-ES"
        case .spanishLatam:       return "es-MX"
        case .spanishUS:          return "es-US"
        case .french:             return "fr-FR"
        case .frenchCanada:       return "fr-CA"
        case .german:             return "de-DE"
        case .italian:            return "it-IT"
        case .portuguese:         return "pt-PT"
        case .portugueseBrazil:   return "pt-BR"
        case .chineseSimplified:  return "zh-CN"
        case .chineseTraditional: return "zh-TW"
        case .japanese:           return "ja-JP"
        case .korean:             return "ko-KR"
        case .russian:            return "ru-RU"
        case .arabic:             return "ar-SA"
        case .hindi:              return "hi-IN"
        }
    }

    var locale: Locale {
        Locale(identifier: speechLocaleIdentifier)
    }

    var nlLanguage: NLLanguage {
        switch self {
        case .english, .englishUK:                   return .english
        case .spanish, .spanishLatam, .spanishUS:    return .spanish
        case .french, .frenchCanada:                 return .french
        case .german:                                return .german
        case .italian:                               return .italian
        case .portuguese, .portugueseBrazil:         return .portuguese
        case .chineseSimplified:                     return .simplifiedChinese
        case .chineseTraditional:                    return .traditionalChinese
        case .japanese:                              return .japanese
        case .korean:                                return .korean
        case .russian:                               return .russian
        case .arabic:                                return .arabic
        case .hindi:                                 return .hindi
        }
    }

    var ttsVoiceLanguage: String {
        switch self {
        case .chineseSimplified:  return "zh-CN"
        case .chineseTraditional: return "zh-TW"
        case .englishUK:          return "en-GB"
        case .spanishLatam:       return "es-MX"
        case .spanishUS:          return "es-US"
        case .frenchCanada:       return "fr-CA"
        case .portugueseBrazil:   return "pt-BR"
        case .portuguese:         return "pt-PT"
        default: return rawValue
        }
    }

    var translationLocaleLanguage: Locale.Language {
        switch self {
        case .chineseSimplified:  return Locale.Language(identifier: "zh-Hans")
        case .chineseTraditional: return Locale.Language(identifier: "zh-Hant")
        case .spanishLatam:       return Locale.Language(identifier: "es")
        case .spanishUS:          return Locale.Language(identifier: "es")
        case .englishUK:          return Locale.Language(identifier: "en-GB")
        case .frenchCanada:       return Locale.Language(identifier: "fr")
        case .portugueseBrazil:   return Locale.Language(identifier: "pt-BR")
        default: return Locale.Language(identifier: rawValue)
        }
    }

    static func from(nlLanguage: NLLanguage) -> Language? {
        // Return the first base language match (regional variants share the same NLLanguage)
        allCases.first { $0.nlLanguage == nlLanguage }
    }

    static func from(localeIdentifier: String) -> Language? {
        let normalized = localeIdentifier.lowercased().replacingOccurrences(of: "_", with: "-")
        // Try exact match on speechLocaleIdentifier first
        if let exact = allCases.first(where: { normalized == $0.speechLocaleIdentifier.lowercased() }) {
            return exact
        }
        // Then prefix match on rawValue
        if let prefix = allCases.first(where: { normalized.hasPrefix($0.rawValue.lowercased()) }) {
            return prefix
        }
        // Finally try 2-letter prefix
        let short = String(normalized.prefix(2))
        return allCases.first { $0.rawValue.hasPrefix(short) }
    }
}
