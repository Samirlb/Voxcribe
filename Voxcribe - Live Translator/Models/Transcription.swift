import Foundation

enum Speaker: String, Codable, Sendable {
    case speakerA
    case speakerB

    var label: String {
        switch self {
        case .speakerA: "A"
        case .speakerB: "B"
        }
    }
}

struct TranscriptionEntry: Identifiable, Sendable {
    let id: UUID
    var originalText: String
    var translatedText: String?
    var sourceLanguage: Language
    var targetLanguage: Language
    let timestamp: Date
    var speaker: Speaker?
    var isFinal: Bool

    init(
        id: UUID = UUID(),
        originalText: String,
        translatedText: String? = nil,
        sourceLanguage: Language,
        targetLanguage: Language,
        timestamp: Date = Date(),
        speaker: Speaker? = nil,
        isFinal: Bool = false
    ) {
        self.id = id
        self.originalText = originalText
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.timestamp = timestamp
        self.speaker = speaker
        self.isFinal = isFinal
    }
}

enum TranscriptionState: Sendable, Equatable {
    case idle
    case listening
    case processing
    case error(String)
}

enum TranslationEngine: String, CaseIterable, Identifiable, Codable, Sendable {
    case local
    case online
    case auto

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .local: String(localized: "Local (Apple)")
        case .online: String(localized: "Online (MyMemory)")
        case .auto: String(localized: "Auto")
        }
    }
}
