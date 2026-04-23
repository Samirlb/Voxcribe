import Foundation

@Observable
@MainActor
final class ConversationController {
    var isActive = false
    var languageA: Language = .english
    var languageB: Language = .spanish
    var currentSpeaker: Speaker = .speakerA

    func activeSpeakerLanguage() -> Language {
        currentSpeaker == .speakerA ? languageA : languageB
    }

    func targetLanguageForCurrentSpeaker() -> Language {
        currentSpeaker == .speakerA ? languageB : languageA
    }

    func assignSpeaker(detectedLanguage: Language) {
        if detectedLanguage == languageA || detectedLanguage == languageB {
            currentSpeaker = detectedLanguage == languageA ? .speakerA : .speakerB
        }
    }

    func swapLanguages() {
        let temp = languageA
        languageA = languageB
        languageB = temp
    }

    func reset() {
        currentSpeaker = .speakerA
    }
}
