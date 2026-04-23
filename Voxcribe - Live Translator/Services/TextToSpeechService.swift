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

    private var speakContinuation: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Speak text and wait until TTS finishes. Use this to coordinate with recognition.
    func speakAndWait(_ text: String, in language: Language) async {
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
        utterance.postUtteranceDelay = 0.15

        if let voice = selectVoice(for: language) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: language.ttsVoiceLanguage)
        }

        AppLogger.tts.debug("Speaking (\(language.displayName)): \(trimmed.prefix(40))")

        await withCheckedContinuation { continuation in
            self.speakContinuation = continuation
            self.synthesizer.speak(utterance)
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        speakContinuation?.resume()
        speakContinuation = nil
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
            guard let self else { return }
            self.isSpeaking = false
            self.speakContinuation?.resume()
            self.speakContinuation = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.isSpeaking = false
            self.speakContinuation?.resume()
            self.speakContinuation = nil
        }
    }
}
