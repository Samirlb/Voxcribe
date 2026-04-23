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

    private var restartTimer: Timer?
    private var retryCount = 0
    private let maxRetries = 3
    private let autoRestartInterval: TimeInterval = 45

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

        setupRecognizer(for: language)
        startNetworkMonitoring()
        beginRecognitionTask()
        scheduleAutoRestart()
    }

    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        recognitionRequest?.append(buffer)
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

        isRecognizing = false
        currentPartialText = ""
        languageDetectionBuffer = ""
        languageConfirmationCount = 0
        pendingLanguage = nil

        AppLogger.speech.info("Speech recognition stopped")
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

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        request.requiresOnDeviceRecognition = !isOnline

        recognitionRequest = request

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let text = result.bestTranscription.formattedString

                if result.isFinal {
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.currentPartialText = ""
                        self.detectLanguage(in: text)
                        self.onFinalResult?(text)
                        AppLogger.speech.debug("Final: \(text.prefix(60))...")
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
        recognitionTask?.cancel()
        recognitionRequest?.endAudio()
        recognitionTask = nil
        recognitionRequest = nil

        beginRecognitionTask()
        scheduleAutoRestart()
    }

    private func handleRecognitionError(_ error: Error) {
        let nsError = error as NSError

        if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216 {
            return
        }

        if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110 {
            AppLogger.speech.debug("No speech detected, restarting...")
            restartRecognitionTask()
            return
        }

        AppLogger.speech.error("Recognition error: \(error.localizedDescription)")

        retryCount += 1
        if retryCount <= maxRetries {
            AppLogger.speech.info("Retrying recognition (\(self.retryCount)/\(self.maxRetries))")
            Task {
                try? await Task.sleep(for: .milliseconds(500 * retryCount))
                restartRecognitionTask()
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
                guard let self, self.isRecognizing else { return }
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
                    if self.isRecognizing {
                        self.restartRecognitionTask()
                    }
                }
            }
        }
        monitor.start(queue: monitorQueue)
        pathMonitor = monitor
    }
}
