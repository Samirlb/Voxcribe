<div align="center">

# 🎙️ Voxcribe — Live Translator

**Real-time speech translation for macOS & iOS**

Capture audio from your microphone or system audio, transcribe it live, and get instant translations — all powered by on-device Apple intelligence.

[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2026%20|%20iOS%2026-007AFF?style=flat-square&logo=apple&logoColor=white)](https://developer.apple.com)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-blue?style=flat-square&logo=swift&logoColor=white)](https://developer.apple.com/swiftui/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

<br/>

<img src="https://img.shields.io/badge/🎙️_Microphone-Capture-FF6B6B?style=for-the-badge" />
<img src="https://img.shields.io/badge/🖥️_System_Audio-Capture-4ECDC4?style=for-the-badge" />
<img src="https://img.shields.io/badge/💬_Conversation-Mode-FFD93D?style=for-the-badge" />
<img src="https://img.shields.io/badge/🔊_Text_to_Speech-Playback-6C5CE7?style=for-the-badge" />

</div>

---

## ✨ Features

### 🎯 Core
- **Real-time transcription** — Live speech-to-text using Apple's `SFSpeechRecognizer`
- **Instant translation** — On-device translation via Apple's `Translation` framework
- **Text-to-speech** — Hear translations read aloud with `AVSpeechSynthesizer`
- **System audio capture** — Capture any app's audio on macOS via `ScreenCaptureKit` (calls, videos, podcasts)
- **Conversation mode** — Bidirectional translation with auto language detection and speaker identification

### 🌍 18 Languages with Regional Variants

| Flag | Language | Flag | Language |
|:----:|----------|:----:|----------|
| 🇺🇸 | English | 🇬🇧 | English (UK) |
| 🇪🇸 | Español (España) | 🇲🇽 | Español (Latinoamérica) |
| 🇺🇸 | Español (EE.UU.) | 🇫🇷 | Français |
| 🇨🇦 | Français (Canada) | 🇩🇪 | Deutsch |
| 🇮🇹 | Italiano | 🇵🇹 | Português (Portugal) |
| 🇧🇷 | Português (Brasil) | 🇨🇳 | 中文 (简体) |
| 🇹🇼 | 中文 (繁體) | 🇯🇵 | 日本語 |
| 🇰🇷 | 한국어 | 🇷🇺 | Русский |
| 🇸🇦 | العربية | 🇮🇳 | हिन्दी |

### 🎨 Design
- **Liquid Glass UI** — Modern glass-morphism design with translucent cards and gradients
- **Adaptive layout** — Full window on iOS, compact floating panel on macOS
- **Persistent preferences** — All settings saved via `UserDefaults`

---

## 📱 Screenshots

> *Coming soon — build and run to see the glass-morphism UI in action!*

---

## 🏗️ Architecture

Voxcribe follows a clean **MVVM** architecture with a service layer:

```
Voxcribe - Live Translator/
├── App/
│   └── VoxcribeApp.swift              # Entry point, macOS MenuBarExtra
├── Models/
│   ├── Language.swift                  # 18 languages with flags, BCP-47 codes
│   ├── Transcription.swift             # Transcription entry model
│   └── AppLanguage.swift               # UI localization model
├── Services/
│   ├── AudioCaptureService.swift       # Mic + ScreenCaptureKit system audio
│   ├── SpeechRecognitionService.swift  # SFSpeechRecognizer with buffering
│   ├── TranslationService.swift        # Apple Translation framework
│   └── TextToSpeechService.swift       # AVSpeechSynthesizer async wrapper
├── Features/
│   ├── Transcription/
│   │   ├── ViewModels/
│   │   │   └── TranscriptionViewModel.swift  # Main orchestrator
│   │   └── Views/
│   │       ├── TranscriptionView.swift        # Main UI
│   │       ├── ChatTranscriptionView.swift    # Chat bubbles
│   │       └── CompactTranscriptionView.swift # macOS compact
│   ├── Conversation/
│   │   └── ConversationController.swift       # Turn-based bilingual chat
│   └── Settings/
│       ├── ViewModels/
│       │   └── SettingsViewModel.swift        # Persisted settings
│       └── Views/
│           └── SettingsView.swift             # Glass-card settings
└── Core/
    ├── DesignSystem/
    │   ├── DesignTokens.swift          # Colors, spacing, radii
    │   └── VoxcribeStyles.swift        # Reusable view modifiers
    ├── Extensions/
    │   └── View+Extensions.swift       # SwiftUI helpers
    └── Utilities/
        ├── FloatingPanel.swift         # macOS NSPanel
        ├── PermissionsManager.swift    # Mic + speech permissions
        └── AppLogger.swift             # Unified logging
```

### Data Flow

```
┌──────────────┐    Audio     ┌────────────────────┐   Text    ┌─────────────────────┐
│ AudioCapture │ ──────────▸  │ SpeechRecognition  │ ───────▸  │  TranscriptionVM    │
│   Service    │   Buffers    │     Service         │  Partial  │   (Orchestrator)    │
└──────────────┘              └────────────────────┘  + Final   └──────┬──────────────┘
  ▲ Mic / System                                                       │
  │   Audio                                         ┌─────────────────┤
  │                                                 ▼                  ▼
  │                                          ┌──────────────┐  ┌──────────────┐
  │                                          │ Translation  │  │ Conversation │
  │         ◀── Pause during TTS ──────────  │   Service    │  │  Controller  │
  │                                          └──────────────┘  └──────────────┘
  │                                                 │
  │                                                 ▼
  │                                          ┌──────────────┐
  └───────── Resume after TTS ◀──────────    │  TTS Service │
                                             └──────────────┘
```

---

## 🚀 Getting Started

### Requirements

| Requirement | Version |
|-------------|---------|
| **Xcode** | 26.0 beta or later |
| **macOS** | 26.3+ (Tahoe) |
| **iOS** | 26.4+ |
| **Swift** | 6.0 |

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Samirlb/Voxcribe.git
   cd voxcribe
   ```

2. **Open in Xcode**
   ```bash
   open "Voxcribe - Live Translator.xcodeproj"
   ```

3. **Select your target**
   - **macOS**: Select `My Mac` as destination
   - **iOS**: Select a simulator or connected device

4. **Build & Run** — `⌘R`

### Permissions

The app will request the following permissions on first launch:

| Permission | Purpose |
|------------|---------|
| 🎙️ **Microphone** | Capture voice for transcription |
| 🗣️ **Speech Recognition** | Convert speech to text |
| 🖥️ **Screen Recording** | System audio capture *(macOS only)* |

---

## 🎮 Usage

### Translation Mode

1. Select your **source language** (what you're hearing) and **target language** (translation output)
2. Choose audio source: **🎙️ Microphone** or **🖥️ System Audio** *(macOS)*
3. Tap the **record button** to start
4. Speak or play audio — translations appear in real-time
5. Enable **TTS** in settings to hear translations read aloud

### Conversation Mode

1. Switch to **Conversation** mode in the control bar
2. Set **Language A** and **Language B** in settings (e.g., English ↔ Spanish)
3. Start recording — the app auto-detects which language is being spoken
4. Each speaker sees their words translated to the other language
5. Speaker turns are tracked automatically with color-coded chat bubbles

### System Audio Capture *(macOS)*

Translate audio from any app — Zoom calls, YouTube videos, podcasts:

1. Switch to **🖥️ System Audio** in the source picker
2. Grant Screen Recording permission when prompted
3. Start recording — all system audio (except Voxcribe itself) is captured and translated

---

## ⚙️ Configuration

All settings are persisted automatically via `UserDefaults`:

| Setting | Description | Default |
|---------|-------------|---------|
| **TTS Enabled** | Read translations aloud | Off |
| **TTS Rate** | Speech speed (0.1 – 1.0) | 0.5 |
| **Show Original** | Display source text alongside translation | On |
| **Partial Results** | Show in-progress transcription | On |
| **Font Size** | Transcript text size | 16pt |
| **Silence Timeout** | Seconds of silence before finalizing | 2.0s |

---

## 🔧 Technical Highlights

<details>
<summary><b>🔇 TTS Feedback Loop Prevention</b></summary>

When TTS reads a translation aloud, the microphone would pick it up and create an infinite loop. Voxcribe solves this by:
1. Pausing audio capture and speech recognition before TTS starts
2. Using async `speakAndWait()` with `CheckedContinuation`
3. Resuming capture with a 300ms delay buffer after TTS completes
</details>

<details>
<summary><b>🔄 Zero-Gap Audio Buffering</b></summary>

During the ~150ms speech recognizer restart, audio frames are buffered (up to 10 frames) in a `pendingBuffers` array and flushed when the new recognition task starts — ensuring no spoken words are lost between segments.
</details>

<details>
<summary><b>🇨🇳 CJK Language Finalization</b></summary>

Apple's `SFSpeechRecognizer` rarely fires `isFinal` for Chinese, Japanese, and Korean. Voxcribe implements text-stability detection: when partial text stops changing for `silenceTimeout` seconds, the segment is finalized regardless of audio level.
</details>

<details>
<summary><b>💬 Conversation Turn Detection</b></summary>

Uses `NLLanguageRecognizer` with biased `languageHints` for the two conversation languages. After each finalized segment, the detected language determines the speaker, and the recognizer switches to the *other* language for the next expected turn.
</details>

<details>
<summary><b>🖥️ ScreenCaptureKit Integration</b></summary>

System audio capture uses `SCStream` with `capturesAudio=true` and `excludesCurrentProcessAudio=true` (prevents feedback). Video is minimized to 2×2px at 1fps to reduce overhead. `CMSampleBuffer` is converted to `AVAudioPCMBuffer` for the speech recognizer.
</details>

---

## 🤝 Contributing

Contributions are welcome! Here's how to get started:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Commit** your changes: `git commit -m 'Add amazing feature'`
4. **Push** to the branch: `git push origin feature/amazing-feature`
5. **Open** a Pull Request

### Development Tips

- The project uses **PBXFileSystemSynchronizedRootGroup** — new Swift files are auto-discovered from the filesystem (no manual `project.pbxproj` edits needed)
- **Swift 6 concurrency**: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — all code defaults to MainActor; services use `@unchecked Sendable`
- Build for macOS: `xcodebuild -scheme "Voxcribe - Live Translator" -destination 'platform=macOS' build`
- Build for iOS Simulator: `xcodebuild -scheme "Voxcribe - Live Translator" -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build`

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Apple Frameworks**: Speech, Translation, AVFoundation, ScreenCaptureKit, NaturalLanguage
- **SwiftUI**: Liquid Glass design language
- Built with ❤️ using Xcode 26

---

<div align="center">

**⭐ Star this repo if you find it useful!**

Made with 🎙️ by [Samir](https://github.com/yourusername)

</div>
