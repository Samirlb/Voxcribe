import AVFoundation
import OSLog
#if os(macOS)
import ScreenCaptureKit
#endif

enum AudioSource: String, CaseIterable, Identifiable, Sendable {
    case microphone
    case systemAudio

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .microphone: "Microphone"
        case .systemAudio: "System Audio"
        }
    }

    var icon: String {
        switch self {
        case .microphone: "mic.fill"
        case .systemAudio: "desktopcomputer"
        }
    }

    static var availableSources: [AudioSource] {
        #if os(macOS)
        return [.microphone, .systemAudio]
        #else
        return [.microphone]
        #endif
    }
}

@Observable
@MainActor
final class AudioCaptureService: @unchecked Sendable {

    // MARK: - State
    var audioLevel: Float = 0
    var isCapturing = false
    var currentSource: AudioSource = .microphone

    // MARK: - Private
    private var audioEngine: AVAudioEngine?
    private var noiseFloor: Float = -50
    private var bufferHandler: (@Sendable (AVAudioPCMBuffer) -> Void)?

    #if os(macOS)
    private var scStream: SCStream?
    private var streamOutput: SystemAudioStreamOutput?
    #endif

    // MARK: - Config
    private let noiseFloorSmoothing: Float = 0.05
    private let rmsWeight: Float = 0.7
    private let peakWeight: Float = 0.3
    private let levelSmoothing: Float = 0.3

    // MARK: - Public API

    func setBufferHandler(_ handler: @escaping @Sendable (AVAudioPCMBuffer) -> Void) {
        self.bufferHandler = handler
    }

    func startCapturing(source: AudioSource = .microphone) throws {
        guard !isCapturing else { return }
        currentSource = source

        #if os(macOS)
        if source == .systemAudio {
            Task { try await startSystemAudioCaptureInternal() }
            return
        }
        #endif

        try startMicrophoneCapture()
    }

    func stopCapturing() {
        #if os(macOS)
        if currentSource == .systemAudio {
            stopSystemAudioCapture()
            return
        }
        #endif

        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil

        isCapturing = false
        audioLevel = 0
        noiseFloor = -50

        AppLogger.audio.info("Audio capture stopped")
    }

    // MARK: - Microphone Capture

    private func startMicrophoneCapture() throws {
        #if os(iOS)
        try configureAudioSession()
        #endif

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        guard format.sampleRate > 0 else {
            throw AudioCaptureError.invalidFormat
        }

        AppLogger.audio.info("Mic format: \(format.sampleRate)Hz, \(format.channelCount)ch")

        let handler = bufferHandler
        let rmsW = rmsWeight
        let peakW = peakWeight
        let nfSmooth = noiseFloorSmoothing
        let smooth = levelSmoothing
        var localNoiseFloor: Float = -50

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            Self.processAudioBuffer(
                buffer, handler: handler,
                rmsW: rmsW, peakW: peakW, nfSmooth: nfSmooth, smooth: smooth,
                localNoiseFloor: &localNoiseFloor, weakSelf: self
            )
        }

        engine.prepare()
        try engine.start()

        audioEngine = engine
        isCapturing = true
        AppLogger.audio.info("Microphone capture started")
    }

    // MARK: - Shared audio processing

    nonisolated static func processAudioBuffer(
        _ buffer: AVAudioPCMBuffer,
        handler: (@Sendable (AVAudioPCMBuffer) -> Void)?,
        rmsW: Float, peakW: Float, nfSmooth: Float, smooth: Float,
        localNoiseFloor: inout Float, weakSelf: AudioCaptureService?
    ) {
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

        if combinedDB < localNoiseFloor + 5 {
            localNoiseFloor = localNoiseFloor * (1 - nfSmooth) + combinedDB * nfSmooth
        }

        let dynamicRange: Float = 60
        let normalized = max(0, min(1, (combinedDB - localNoiseFloor) / dynamicRange))

        Task { @MainActor [weak weakSelf] in
            guard let self = weakSelf else { return }
            self.audioLevel = self.audioLevel * (1 - smooth) + normalized * smooth
        }

        handler?(buffer)
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

    // MARK: - macOS System Audio (ScreenCaptureKit)

    #if os(macOS)
    private func startSystemAudioCaptureInternal() async throws {
        let availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)

        guard let display = availableContent.displays.first else {
            throw AudioCaptureError.invalidFormat
        }

        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        let config = SCStreamConfiguration()
        config.capturesAudio = true
        config.excludesCurrentProcessAudio = true
        config.sampleRate = 48000
        config.channelCount = 1

        // We only want audio, minimize video overhead
        config.width = 2
        config.height = 2
        config.minimumFrameInterval = CMTime(value: 1, timescale: 1)

        let handler = bufferHandler
        let rmsW = rmsWeight
        let peakW = peakWeight
        let nfSmooth = noiseFloorSmoothing
        let smooth = levelSmoothing

        let output = SystemAudioStreamOutput(
            handler: handler,
            rmsW: rmsW, peakW: peakW, nfSmooth: nfSmooth, smooth: smooth,
            service: self
        )
        streamOutput = output

        let stream = SCStream(filter: filter, configuration: config, delegate: nil)
        try stream.addStreamOutput(output, type: .audio, sampleHandlerQueue: .global(qos: .userInteractive))
        try await stream.startCapture()

        scStream = stream
        isCapturing = true
        AppLogger.audio.info("System audio capture started")
    }

    private func stopSystemAudioCapture() {
        Task {
            try? await scStream?.stopCapture()
            scStream = nil
            streamOutput = nil
            isCapturing = false
            audioLevel = 0
            noiseFloor = -50
            AppLogger.audio.info("System audio capture stopped")
        }
    }
    #endif
}

// MARK: - macOS Stream Output

#if os(macOS)
final class SystemAudioStreamOutput: NSObject, SCStreamOutput, @unchecked Sendable {
    private let handler: (@Sendable (AVAudioPCMBuffer) -> Void)?
    private let rmsW: Float
    private let peakW: Float
    private let nfSmooth: Float
    private let smooth: Float
    private weak var service: AudioCaptureService?
    private var localNoiseFloor: Float = -50

    init(handler: (@Sendable (AVAudioPCMBuffer) -> Void)?,
         rmsW: Float, peakW: Float, nfSmooth: Float, smooth: Float,
         service: AudioCaptureService) {
        self.handler = handler
        self.rmsW = rmsW
        self.peakW = peakW
        self.nfSmooth = nfSmooth
        self.smooth = smooth
        self.service = service
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }
        guard let formatDesc = sampleBuffer.formatDescription,
              let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc) else { return }

        guard let blockBuffer = sampleBuffer.dataBuffer else { return }
        let length = CMBlockBufferGetDataLength(blockBuffer)
        guard length > 0 else { return }

        var dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: nil, dataPointerOut: &dataPointer)
        guard let dataPointer else { return }

        let frameCount = length / MemoryLayout<Float>.size
        guard frameCount > 0 else { return }

        guard let audioFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: asbd.pointee.mSampleRate,
            channels: AVAudioChannelCount(asbd.pointee.mChannelsPerFrame),
            interleaved: false
        ) else { return }

        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(frameCount)) else { return }
        pcmBuffer.frameLength = AVAudioFrameCount(frameCount)

        if let dest = pcmBuffer.floatChannelData?[0] {
            dataPointer.withMemoryRebound(to: Float.self, capacity: frameCount) { src in
                dest.update(from: src, count: frameCount)
            }
        }

        AudioCaptureService.processAudioBuffer(
            pcmBuffer, handler: handler,
            rmsW: rmsW, peakW: peakW, nfSmooth: nfSmooth, smooth: smooth,
            localNoiseFloor: &localNoiseFloor, weakSelf: service
        )
    }
}
#endif

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
