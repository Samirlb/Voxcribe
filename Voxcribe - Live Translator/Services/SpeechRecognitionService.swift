import Speech
import NaturalLanguage
import Network
import OSLog

@Observable
final class SpeechRecognitionService: @unchecked Sendable {
    var currentPartialText: String = ""
    var isRecognizing = false
    var detectedLanguage: Language?
    var isOnline = true

    var onPartialResult: ((String) -> Void)?
    var onFinalResult: ((String) -> Void)?
    var onLanguageDetected: ((Language) -> Void)?

    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var pendingBuffers: [AVAudioPCMBuffer] = []

    private var restartTimer: Timer?
    private var retryCount = 0
    private let maxRetries = 3
    private let autoRestartInterval: TimeInterval = 45

    private var isRestarting = false
    private(set) var isPaused = false

    private let languageRecognizer = NLLanguageRecognizer()
    private var languageConfirmationCount = 0
    private var pendingLanguage: Language?
    private let languageChangeThreshold: Double = 0.5
    private let newLanguageThreshold: Double = 0.7
    private let requiredConfirmations = 3
    private var languageDetectionBuffer: String = ""

    private var pathMonitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "com.samir.Voxcribe.networkMonitor")

    private var currentLanguage: Language = .english

    func startRecognition(language: Language) {
        currentLanguage = language
        retryCount = 0
        isPaused = false
        isRestarting = false

        setupRecognizer(for: language)
        startNetworkMonitoring()
        beginRecognitionTask()
        scheduleAutoRestart()
    }

    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard !isPaused else { return }
        if let request = recognitionRequest {
            for pending in pendingBuffers {
                request.append(pending)
            }
            pendingBuffers.removeAll()
            request.append(buffer)
        } else if isRestarting {
            pendingBuffers.append(buffer)
            if pendingBuffers.count > 10 {
                pendingBuffers.removeFirst()
            }
        }
    }

    func stopRecognition() {
        restartTimer?.invalidate()
        restartTimer = nil
        pathMonitor?.cancel()
        pathMonitor = nil

        recognitionTask?.cancel()
        recognitionRequest?.endAudio()
        recognitionTask = nil
        recognitionRequest = nil
        recognizer = nil
        pendingBuffers.removeAll()

        isRecognizing = false
        isPaused = false
        isRestarting = false
        currentPartialText = ""
        languageDetectionBuffer = ""
        languageConfirmationCount = 0
        pendingLanguage = nil

        AppLogger.speech.info("Speech recognition stopped")
    }

    func pause() {
        guard isRecognizing, !isPaused else { return }
        isPaused = true
        restartTimer?.invalidate()
        restartTimer = nil

        recognitionTask?.cancel()
        recognitionRequest?.endAudio()
        recognitionTask = nil
        recognitionRequest = nil
        pendingBuffers.removeAll()

        AppLogger.speech.info("Speech recognition paused (TTS)")
    }

    func resume() {
        guard isRecognizing, isPaused else { return }
        isPaused = false
        isRestarting = false
        retryCount = 0

        setupRecognizer(for: currentLanguage)
        beginRecognitionTask()
        scheduleAutoRestart()
        AppLogger.speech.info("Speech recognition resumed")
    }

    func changeLanguage(_ language: Language) {
        let wasRecognizing = isRecognizing
        if wasRecognizing {
            stopRecognition()
            startRecognition(language: language)
        } else {
            currentLanguage = language
        }
    }

    // MARK: - Private

    private func setupRecognizer(for language: Language) {
        let locale = Locale(identifier: language.speechLocaleIdentifier)
        recognizer = SFSpeechRecognizer(locale: locale)

        guard recognizer?.isAvailable == true else {
            AppLogger.speech.error("Recognizer not available for \(language.speechLocaleIdentifier)")
            return
        }

        AppLogger.speech.info("Recognizer configured for \(language.speechLocaleIdentifier)")
    }

    private func beginRecognitionTask() {
        guard let recognizer, recognizer.isAvailable else {
            AppLogger.speech.error("Recognizer unavailable, cannot start task")
            return
        }
        guard !isPaused else { return }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        request.requiresOnDeviceRecognition = !isOnline

        recognitionRequest = request

        // Flush audio that arrived during restart
        for pending in pendingBuffers {
            request.append(pending)
        }
        pendingBuffers.removeAll()

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let text = result.bestTranscription.formattedString

                if result.isFinal {
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        self.currentPartialText = ""
                        if !trimmed.isEmpty {
                            self.detectLanguage(in: trimmed)
                            self.onFinalResult?(trimmed)
                            AppLogger.speech.debug("Final: \(trimmed.prefix(60))...")
                        }
                    }
                    self.restartRecognitionTask()
                } else {
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.currentPartialText = text
                        self.onPartialResult?(text)
                    }
                }
            }

            if let error {
                Task { @MainActor [weak self] in
                    self?.handleRecognitionError(error)
                }
            }
        }

        isRecognizing = true
        AppLogger.speech.info("Recognition task started (online: \(self.isOnline))")
    }

    private func restartRecognitionTask() {
        restartRecognitionTaskInternal()
    }

    /// Called externally when silence/stability detection finalizes partial text
    func forceRestart() {
        restartRecognitionTaskInternal()
    }

    private func restartRecognitionTaskInternal() {
        guard !isRestarting, !isPaused else { return }
        isRestarting = true

        recognitionTask?.cancel()
        recognitionRequest?.endAudio()
        recognitionTask = nil
        recognitionRequest = nil

        Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .milliseconds(150))
            self.isRestarting = false
            guard self.isRecognizing, !self.isPaused else { return }
            self.beginRecognitionTask()
            self.scheduleAutoRestart()
        }
    }

    private func handleRecognitionError(_ error: Error) {
        let nsError = error as NSError

        if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216 {
            return
        }

        if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110 {
            AppLogger.speech.debug("No speech detected, waiting for auto-restart")
            return
        }

        AppLogger.speech.error("Recognition error: \(error.localizedDescription)")

        retryCount += 1
        if retryCount <= maxRetries {
            AppLogger.speech.info("Retrying recognition (\(self.retryCount)/\(self.maxRetries))")
            Task {
                try? await Task.sleep(for: .seconds(1))
                guard !self.isPaused else { return }
                self.setupRecognizer(for: self.currentLanguage)
                self.isRestarting = false
                self.restartRecognitionTask()
            }
        } else {
            AppLogger.speech.error("Max retries reached, stopping recognition")
            isRecognizing = false
        }
    }

    private func scheduleAutoRestart() {
        restartTimer?.invalidate()
        restartTimer = Timer.scheduledTimer(
            withTimeInterval: autoRestartInterval,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isRecognizing, !self.isPaused else { return }
                AppLogger.speech.debug("Auto-restart after \(self.autoRestartInterval)s")
                self.restartRecognitionTask()
            }
        }
    }

    // MARK: - Language Detection

    private func detectLanguage(in text: String) {
        languageDetectionBuffer += " " + text
        if languageDetectionBuffer.count > 100 {
            languageDetectionBuffer = String(languageDetectionBuffer.suffix(50))
        }

        guard languageDetectionBuffer.count >= 20 else { return }

        languageRecognizer.reset()
        languageRecognizer.processString(languageDetectionBuffer)

        let hypotheses = languageRecognizer.languageHypotheses(withMaximum: 3)
        guard let topResult = hypotheses.max(by: { $0.value < $1.value }) else { return }
        let (nlLang, confidence) = (topResult.key, topResult.value)

        guard let detected = Language.from(nlLanguage: nlLang) else { return }
        if detected == detectedLanguage { return }

        let threshold = detectedLanguage == nil ? languageChangeThreshold : newLanguageThreshold
        guard confidence >= threshold else { return }

        if detected == pendingLanguage {
            languageConfirmationCount += 1
        } else {
            pendingLanguage = detected
            languageConfirmationCount = 1
        }

        if languageConfirmationCount >= requiredConfirmations {
            detectedLanguage = detected
            pendingLanguage = nil
            languageConfirmationCount = 0
            onLanguageDetected?(detected)
            AppLogger.speech.info("Language detected: \(detected.displayName) (confidence: \(confidence))")
        }
    }

    // MARK: - Network Monitoring

    private func startNetworkMonitoring() {
        pathMonitor?.cancel()
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let wasOnline = self.isOnline
                self.isOnline = path.status == .satisfied

                if wasOnline != self.isOnline {
                    AppLogger.speech.info("Network: \(self.isOnline ? "online" : "offline")")
                    if self.isRecognizing, !self.isPaused {
                        self.restartRecognitionTask()
                    }
                }
            }
        }
        monitor.start(queue: monitorQueue)
        pathMonitor = monitor
    }
}
