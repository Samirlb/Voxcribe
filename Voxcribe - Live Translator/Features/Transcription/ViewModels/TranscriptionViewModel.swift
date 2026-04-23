import SwiftUI
import Combine
import OSLog

@Observable
@MainActor
final class TranscriptionViewModel {

    // MARK: - Published State
    var state: TranscriptionState = .idle
    var entries: [TranscriptionEntry] = []
    var currentPartialText: String = ""
    var audioLevel: Float = 0
    var detectedLanguage: Language?

    // MARK: - Settings (bound from SettingsViewModel)
    var sourceLanguage: Language = .english
    var targetLanguage: Language = .spanish
    var translationEngine: TranslationEngine = .auto
    var ttsEnabled: Bool = true
    var showOriginalText: Bool = true
    var showPartialResults: Bool = true
    var silenceTimeout: TimeInterval = 2.0

    // MARK: - Services
    var audioService = AudioCaptureService()
    var speechService = SpeechRecognitionService()
    var translationService = TranslationService()
    var ttsService = TextToSpeechService()
    var conversationController = ConversationController()
    var permissionsManager = PermissionsManager()

    // MARK: - Private
    private var silenceTimer: Timer?
    private var lastSpeechTime: Date = Date()
    private var lastFinalizedText: String = ""
    private var isSpeakingTTS = false
    private var pendingTTSQueue: [(text: String, language: Language)] = []
    private var ttsTask: Task<Void, Never>?

    // MARK: - Lifecycle

    func startListening() {
        guard state != .listening else { return }

        permissionsManager.checkPermissions()
        guard permissionsManager.allPermissionsGranted else {
            state = .error("Permissions not granted")
            return
        }

        let language = conversationController.isActive
            ? conversationController.activeSpeakerLanguage()
            : sourceLanguage

        configureCallbacks()

        do {
            try audioService.startCapturing()
            speechService.startRecognition(language: language)
            state = .listening
            lastFinalizedText = ""
            startSilenceDetection()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func stopListening() {
        silenceTimer?.invalidate()
        silenceTimer = nil

        speechService.stopRecognition()
        audioService.stopCapturing()
        ttsTask?.cancel()
        ttsTask = nil
        isSpeakingTTS = false

        if !currentPartialText.isEmpty {
            finalizeCurrentEntry(text: currentPartialText)
        }

        currentPartialText = ""
        state = .idle
    }

    func toggleListening() {
        if state == .listening || state == .processing {
            stopListening()
        } else {
            startListening()
        }
    }

    func clearEntries() {
        entries.removeAll()
        ttsService.clearHistory()
        translationService.clearCache()
        lastFinalizedText = ""
    }

    func swapLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp

        if conversationController.isActive {
            conversationController.swapLanguages()
        }

        if state == .listening {
            let newLang = conversationController.isActive
                ? conversationController.activeSpeakerLanguage()
                : sourceLanguage
            speechService.changeLanguage(newLang)
        }
    }

    // MARK: - Callbacks

    private func configureCallbacks() {
        audioService.setBufferHandler { [weak self] buffer in
            Task { @MainActor [weak self] in
                guard let self, !self.isSpeakingTTS else { return }
                self.speechService.appendAudioBuffer(buffer)
            }
        }

        speechService.onPartialResult = { [weak self] text in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.currentPartialText = text
                self.lastSpeechTime = Date()
            }
        }

        speechService.onFinalResult = { [weak self] text in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.finalizeCurrentEntry(text: text)
                self.currentPartialText = ""
                self.lastSpeechTime = Date()
            }
        }

        speechService.onLanguageDetected = { [weak self] language in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.detectedLanguage = language

                if self.conversationController.isActive {
                    self.conversationController.assignSpeaker(detectedLanguage: language)
                }
            }
        }
    }

    // MARK: - Entry Management

    private func finalizeCurrentEntry(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Prevent duplicate translations of the same text
        if trimmed == lastFinalizedText { return }
        lastFinalizedText = trimmed

        let source: Language
        let target: Language
        let speaker: Speaker?

        if conversationController.isActive {
            source = conversationController.activeSpeakerLanguage()
            target = conversationController.targetLanguageForCurrentSpeaker()
            speaker = conversationController.currentSpeaker
        } else {
            source = detectedLanguage ?? sourceLanguage
            target = targetLanguage
            speaker = nil
        }

        let entry = TranscriptionEntry(
            originalText: trimmed,
            sourceLanguage: source,
            targetLanguage: target,
            speaker: speaker,
            isFinal: true
        )

        entries.append(entry)
        let entryID = entry.id

        Task {
            await translateAndSpeak(id: entryID, text: trimmed, source: source, target: target)
        }
    }

    private func translateAndSpeak(id: UUID, text: String, source: Language, target: Language) async {
        let previousState = state
        state = .processing

        guard let translated = await translationService.translate(
            text,
            from: source,
            to: target,
            engine: translationEngine
        ) else {
            if state == .processing { state = previousState }
            return
        }

        if let index = entries.firstIndex(where: { $0.id == id }) {
            entries[index].translatedText = translated
        }

        if state == .processing {
            state = .listening
        }

        // TTS with audio coordination to prevent feedback loop
        guard ttsEnabled else { return }
        await speakWithCoordination(text: translated, language: target)
    }

    /// Pauses recognition, speaks TTS, then resumes recognition
    private func speakWithCoordination(text: String, language: Language) async {
        guard state == .listening || state == .processing else { return }

        isSpeakingTTS = true
        speechService.pause()
        audioService.stopCapturing()

        // Small delay to let audio hardware settle
        try? await Task.sleep(for: .milliseconds(150))

        await ttsService.speakAndWait(text, in: language)

        // Delay before resuming to avoid picking up echo
        try? await Task.sleep(for: .milliseconds(300))

        guard state == .listening || state == .processing else {
            isSpeakingTTS = false
            return
        }

        // Resume audio capture and recognition
        do {
            try audioService.startCapturing()
        } catch {
            AppLogger.audio.error("Failed to restart audio: \(error.localizedDescription)")
        }
        speechService.resume()
        isSpeakingTTS = false
        lastSpeechTime = Date()
    }

    // MARK: - Silence Detection

    private func startSilenceDetection() {
        silenceTimer?.invalidate()
        lastSpeechTime = Date()

        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard self.state == .listening, !self.isSpeakingTTS else { return }

                let silenceDuration = Date().timeIntervalSince(self.lastSpeechTime)
                let isQuiet = self.audioService.audioLevel < 0.05

                if silenceDuration > self.silenceTimeout && isQuiet && !self.currentPartialText.isEmpty {
                    let text = self.currentPartialText
                    self.currentPartialText = ""
                    self.finalizeCurrentEntry(text: text)
                }
            }
        }
    }
}
