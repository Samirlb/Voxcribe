import AVFoundation
import Speech
internal import os

@Observable
final class PermissionsManager {
    var microphoneGranted = false
    var speechRecognitionGranted = false

    var allPermissionsGranted: Bool {
        microphoneGranted && speechRecognitionGranted
    }

    func checkPermissions() {
        checkMicrophonePermission()
        checkSpeechRecognitionPermission()
    }

    func requestAllPermissions() async {
        await requestMicrophonePermission()
        await requestSpeechRecognitionPermission()
    }

    private func checkMicrophonePermission() {
        microphoneGranted = AVAudioApplication.shared.recordPermission == .granted
    }

    private func checkSpeechRecognitionPermission() {
        speechRecognitionGranted = SFSpeechRecognizer.authorizationStatus() == .authorized
    }

    private func requestMicrophonePermission() async {
        let granted = await AVAudioApplication.requestRecordPermission()
        microphoneGranted = granted
        AppLogger.permissions.info("Microphone permission: \(granted)")
    }

    private func requestSpeechRecognitionPermission() async {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        speechRecognitionGranted = status == .authorized
        AppLogger.permissions.info("Speech recognition permission: \(status == .authorized)")
    }
}
