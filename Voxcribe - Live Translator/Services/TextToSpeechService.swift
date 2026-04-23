import AVFoundation
import OSLog

@Observable
final class TextToSpeechService: NSObject, AVSpeechSynthesizerDelegate {
    var isSpeaking = false
    var isEnabled = true

    private let synthesizer = AVSpeechSynthesizer()
    private var spokenPhrases: Set<String> = []
    private var baseRate: Float = 0.5
    private var currentRate: Float = 0.5
    private let maxRate: Float = 0.6
    private let minRate: Float = 0.4
    private let maxTrackedPhrases = 200

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, in language: Language) {
        guard isEnabled else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if spokenPhrases.contains(trimmed) {
            AppLogger.tts.debug("Skipping duplicate: \(trimmed.prefix(30))")
            return
        }

        trackPhrase(trimmed)
        adaptRate(for: trimmed)

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.rate = currentRate
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.2

        if let voice = selectVoice(for: language) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: language.ttsVoiceLanguage)
        }

        synthesizer.speak(utterance)
        AppLogger.tts.debug("Speaking (\(language.displayName)): \(trimmed.prefix(40))")
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func clearHistory() {
        spokenPhrases.removeAll()
    }

    func setRate(_ rate: Float) {
        baseRate = max(minRate, min(maxRate, rate))
        currentRate = baseRate
    }

    // MARK: - Voice Selection

    private func selectVoice(for language: Language) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(language.ttsVoiceLanguage) }

        let enhanced = voices.first { $0.quality == AVSpeechSynthesisVoiceQuality.enhanced }
        let premium = voices.first { $0.quality == AVSpeechSynthesisVoiceQuality.premium }
        return premium ?? enhanced ?? voices.first
    }

    // MARK: - Rate Adaptation

    private func adaptRate(for text: String) {
        let wordCount = text.split(separator: " ").count
        if wordCount > 20 {
            currentRate = min(maxRate, baseRate * 1.1)
        } else {
            currentRate = baseRate
        }
    }

    // MARK: - Deduplication

    private func trackPhrase(_ phrase: String) {
        spokenPhrases.insert(phrase)
        if spokenPhrases.count > maxTrackedPhrases {
            spokenPhrases.removeFirst()
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.isSpeaking = true
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.isSpeaking = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.isSpeaking = false
        }
    }
}
