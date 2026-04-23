import OSLog

enum AppLogger {
    static let audio = Logger(subsystem: "com.samir.Voxcribe", category: "Audio")
    static let speech = Logger(subsystem: "com.samir.Voxcribe", category: "Speech")
    static let translation = Logger(subsystem: "com.samir.Voxcribe", category: "Translation")
    static let tts = Logger(subsystem: "com.samir.Voxcribe", category: "TTS")
    static let permissions = Logger(subsystem: "com.samir.Voxcribe", category: "Permissions")
    static let general = Logger(subsystem: "com.samir.Voxcribe", category: "General")
}
