import SwiftUI

struct SettingsView: View {
    @Bindable var settings: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                languageSection
                translationSection
                ttsSection
                displaySection
                conversationSection
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Sections

    private var languageSection: some View {
        Section("Language") {
            Picker("Target Language", selection: $settings.targetLanguage) {
                ForEach(Language.allCases) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }

            Picker("App Language", selection: $settings.appLanguage) {
                ForEach(AppLanguage.allCases) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
        }
    }

    private var translationSection: some View {
        Section("Translation") {
            Picker("Engine", selection: $settings.translationEngine) {
                ForEach(TranslationEngine.allCases) { engine in
                    Text(engine.displayName).tag(engine)
                }
            }
        }
    }

    private var ttsSection: some View {
        Section("Text to Speech") {
            Toggle("Enable TTS", isOn: $settings.ttsEnabled)

            if settings.ttsEnabled {
                VStack(alignment: .leading) {
                    Text("Speech Rate")
                        .font(.subheadline)
                    Slider(
                        value: $settings.ttsRate,
                        in: SettingsViewModel.ttsRateRange
                    ) {
                        Text("Rate")
                    } minimumValueLabel: {
                        Text("Slow")
                            .font(.caption2)
                    } maximumValueLabel: {
                        Text("Fast")
                            .font(.caption2)
                    }
                }
            }
        }
    }

    private var displaySection: some View {
        Section("Display") {
            Toggle("Show Original Text", isOn: $settings.showOriginalText)
            Toggle("Show Partial Results", isOn: $settings.showPartialResults)

            VStack(alignment: .leading) {
                Text("Font Size: \(Int(settings.fontSize))pt")
                    .font(.subheadline)
                Slider(
                    value: $settings.fontSize,
                    in: SettingsViewModel.fontSizeRange,
                    step: 1
                )
            }

            VStack(alignment: .leading) {
                Text("Silence Timeout: \(String(format: "%.1f", settings.silenceTimeout))s")
                    .font(.subheadline)
                Slider(
                    value: $settings.silenceTimeout,
                    in: SettingsViewModel.silenceTimeoutRange,
                    step: 0.5
                )
            }
        }
    }

    private var conversationSection: some View {
        Section("Conversation Mode") {
            Toggle("Enable Conversation Mode", isOn: $settings.conversationMode)

            if settings.conversationMode {
                Picker("Language A", selection: $settings.conversationLanguageA) {
                    ForEach(Language.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }

                Picker("Language B", selection: $settings.conversationLanguageB) {
                    ForEach(Language.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
            }
        }
    }
}
