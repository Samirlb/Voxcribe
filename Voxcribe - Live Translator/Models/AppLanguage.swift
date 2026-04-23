import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case system
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case japanese = "ja"
    case korean = "ko"
    case chineseSimplified = "zh-Hans"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: String(localized: "System")
        case .english: "English"
        case .spanish: "Español"
        case .french: "Français"
        case .german: "Deutsch"
        case .japanese: "日本語"
        case .korean: "한국어"
        case .chineseSimplified: "中文"
        }
    }
}
