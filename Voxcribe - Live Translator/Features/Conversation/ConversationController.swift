import Foundation
import NaturalLanguage

@Observable
@MainActor
final class ConversationController {
    var isActive = false
    var languageA: Language = .english
    var languageB: Language = .spanish
    var currentSpeaker: Speaker = .speakerA
    var currentRecognizerLanguage: Language = .english

    private let languageRecognizer = NLLanguageRecognizer()

    struct TurnResult {
        let speaker: Speaker
        let sourceLanguage: Language
        let targetLanguage: Language
        let nextRecognizerLanguage: Language
    }

    func activeSpeakerLanguage() -> Language {
        currentRecognizerLanguage
    }

    func targetLanguageForCurrentSpeaker() -> Language {
        currentRecognizerLanguage == languageA ? languageB : languageA
    }

    /// Called after a segment is finalized — detects speaker from text language and prepares next turn
    func processFinalizedText(_ text: String) -> TurnResult {
        let detected = detectLanguage(in: text)
        let speaker: Speaker = detected == languageA ? .speakerA : .speakerB
        currentSpeaker = speaker

        let target = detected == languageA ? languageB : languageA
        currentRecognizerLanguage = target

        return TurnResult(
            speaker: speaker,
            sourceLanguage: detected,
            targetLanguage: target,
            nextRecognizerLanguage: target
        )
    }

    /// Called when no speech detected — try the other language
    func switchToOtherLanguage() -> Language {
        currentRecognizerLanguage = (currentRecognizerLanguage == languageA) ? languageB : languageA
        return currentRecognizerLanguage
    }

    func start() {
        currentRecognizerLanguage = languageA
        currentSpeaker = .speakerA
    }

    func reset() {
        currentSpeaker = .speakerA
        currentRecognizerLanguage = languageA
    }

    func swapLanguages() {
        let temp = languageA
        languageA = languageB
        languageB = temp
    }

    // MARK: - Language Detection

    private func detectLanguage(in text: String) -> Language {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return currentRecognizerLanguage
        }

        languageRecognizer.reset()
        languageRecognizer.languageHints = [
            languageA.nlLanguage: 0.5,
            languageB.nlLanguage: 0.5
        ]
        languageRecognizer.processString(text)

        let hypotheses = languageRecognizer.languageHypotheses(withMaximum: 5)
        let scoreA = hypotheses[languageA.nlLanguage] ?? 0
        let scoreB = hypotheses[languageB.nlLanguage] ?? 0

        return scoreA >= scoreB ? languageA : languageB
    }
}
