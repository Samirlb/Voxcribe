import AVFoundation
import OSLog

@Observable
@MainActor
final class AudioCaptureService: @unchecked Sendable {

    // MARK: - State
    var audioLevel: Float = 0
    var isCapturing = false

    // MARK: - Private
    private var audioEngine: AVAudioEngine?
    private var noiseFloor: Float = -50

    /// Handler seguro para concurrencia
    private var bufferHandler: (@Sendable (AVAudioPCMBuffer) -> Void)?

    // MARK: - Config
    private let noiseFloorSmoothing: Float = 0.05
    private let rmsWeight: Float = 0.7
    private let peakWeight: Float = 0.3
    private let levelSmoothing: Float = 0.3

    // MARK: - Public API

    func setBufferHandler(_ handler: @escaping @Sendable (AVAudioPCMBuffer) -> Void) {
        self.bufferHandler = handler
    }

    func startCapturing() throws {
        guard !isCapturing else { return }

        #if os(iOS)
        try configureAudioSession()
        #endif

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        guard format.sampleRate > 0 else {
            throw AudioCaptureError.invalidFormat
        }

        AppLogger.audio.info("Audio format: \(format.sampleRate)Hz, \(format.channelCount)ch")

        // Captura valores fuera del hilo de audio
        let handler = bufferHandler
        let rmsW = rmsWeight
        let peakW = peakWeight
        let nfSmooth = noiseFloorSmoothing
        let smooth = levelSmoothing

        var localNoiseFloor: Float = -50

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameCount = Int(buffer.frameLength)
            guard frameCount > 0 else { return }

            var sumSquares: Float = 0
            var peak: Float = 0

            for i in 0..<frameCount {
                let sample = channelData[i]
                sumSquares += sample * sample
                let absSample = abs(sample)
                if absSample > peak { peak = absSample }
            }

            let rms = sqrt(sumSquares / Float(frameCount))
            let rmsDB = 20 * log10(max(rms, 1e-7))
            let peakDB = 20 * log10(max(peak, 1e-7))
            let combinedDB = rmsDB * rmsW + peakDB * peakW

            // Ajuste dinámico del ruido base
            if combinedDB < localNoiseFloor + 5 {
                localNoiseFloor = localNoiseFloor * (1 - nfSmooth) + combinedDB * nfSmooth
            }

            let dynamicRange: Float = 60
            let normalized = max(0, min(1, (combinedDB - localNoiseFloor) / dynamicRange))

            // UI update en MainActor (seguro)
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.audioLevel = self.audioLevel * (1 - smooth) + normalized * smooth
            }

            // Callback externo (NO bloquear)
            handler?(buffer)
        }

        engine.prepare()
        try engine.start()

        audioEngine = engine
        isCapturing = true

        AppLogger.audio.info("Audio capture started")
    }

    func stopCapturing() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil

        isCapturing = false
        audioLevel = 0
        noiseFloor = -50

        AppLogger.audio.info("Audio capture stopped")
    }

    // MARK: - iOS Audio Session

    #if os(iOS)
    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()

        try session.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [
                .defaultToSpeaker,
                .allowBluetooth,
                .mixWithOthers
            ]
        )

        try session.setPreferredSampleRate(16000)
        try session.setPreferredIOBufferDuration(0.02)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        AppLogger.audio.info("Audio session configured")
    }
    #endif

    // MARK: - macOS

    #if os(macOS)
    func startSystemAudioCapture() throws {
        AppLogger.audio.warning("System audio capture not implemented yet")
        try startCapturing()
    }
    #endif
}

// MARK: - Errors

enum AudioCaptureError: LocalizedError {
    case invalidFormat
    case sessionConfigurationFailed
    case engineStartFailed

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid audio format detected"
        case .sessionConfigurationFailed:
            return "Failed to configure audio session"
        case .engineStartFailed:
            return "Failed to start audio engine"
        }
    }
}
