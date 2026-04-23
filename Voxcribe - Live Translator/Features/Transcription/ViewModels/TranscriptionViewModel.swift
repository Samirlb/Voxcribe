import SwiftUI
import Combine

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
    private var currentEntryID: UUID?

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
            startSilenceDetection()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func stopListening() {
        silenceTimer?.invalidate()
        silenceTimer = nil

        audioService.stopCapturing()
        speechService.stopRecognition()

        if !currentPartialText.isEmpty {
            finalizeCurrentEntry(text: currentPartialText)
        }

        currentPartialText = ""
        state = .idle
    }

    func toggleListening() {
        if state == .listening {
            stopListening()
        } else {
            startListening()
        }
    }

    func clearEntries() {
        entries.removeAll()
        ttsService.clearHistory()
        translationService.clearCache()
    }

    func swapLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp

        if conversationController.isActive {
            conversationController.swapLanguages()
        }

        if state == .listening {
            speechService.changeLanguage(sourceLanguage)
        }
    }

    // MARK: - Callbacks

    private func configureCallbacks() {
        audioService.setBufferHandler { [weak self] buffer in
            Task { @MainActor [weak self] in
                self?.speechService.appendAudioBuffer(buffer)
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
            await translateEntry(id: entryID, text: trimmed, source: source, target: target)
        }
    }

    private func translateEntry(id: UUID, text: String, source: Language, target: Language) async {
        state = .processing

        if let translated = await translationService.translate(
            text,
            from: source,
            to: target,
            engine: translationEngine
        ) {
            if let index = entries.firstIndex(where: { $0.id == id }) {
                entries[index].translatedText = translated
            }

            if ttsEnabled {
                ttsService.speak(translated, in: target)
            }
        }

        if state == .processing {
            state = .listening
        }
    }

    // MARK: - Silence Detection

    private func startSilenceDetection() {
        silenceTimer?.invalidate()
        lastSpeechTime = Date()

        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.state == .listening else { return }

                let silenceDuration = Date().timeIntervalSince(self.lastSpeechTime)
                let isQuiet = self.audioService.audioLevel < 0.05

                if silenceDuration > self.silenceTimeout && isQuiet && !self.currentPartialText.isEmpty {
                    self.finalizeCurrentEntry(text: self.currentPartialText)
                    self.currentPartialText = ""
                }
            }
        }
    }
}
