import SwiftUI

struct SettingsView: View {
    @Bindable var settings: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VoxcribeTokens.Spacing.lg) {
                    languageSection
                    translationSection
                    ttsSection
                    displaySection
                    aboutSection
                }
                .padding(.horizontal, VoxcribeTokens.Spacing.lg)
                .padding(.vertical, VoxcribeTokens.Spacing.md)
            }
            .background(settingsBackground)
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var settingsBackground: some View {
        #if os(iOS)
        Color(.systemGroupedBackground).ignoresSafeArea()
        #else
        Color(.windowBackgroundColor).ignoresSafeArea()
        #endif
    }

    // MARK: - Language

    private var languageSection: some View {
        SettingsCard {
            SettingsCardHeader(icon: "globe", title: "Language", color: .blue)

            SettingsRow {
                Label("Target Language", systemImage: "character.bubble")
                    .font(.subheadline)
                Spacer()
                Picker("", selection: $settings.targetLanguage) {
                    ForEach(Language.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .labelsHidden()
                .tint(.secondary)
            }

            Divider().padding(.leading, 36)

            SettingsRow {
                Label("App Language", systemImage: "textformat")
                    .font(.subheadline)
                Spacer()
                Picker("", selection: $settings.appLanguage) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .labelsHidden()
                .tint(.secondary)
            }
        }
    }

    // MARK: - Translation

    private var translationSection: some View {
        SettingsCard {
            SettingsCardHeader(icon: "arrow.triangle.2.circlepath", title: "Translation", color: .orange)

            VStack(alignment: .leading, spacing: VoxcribeTokens.Spacing.md) {
                Text("Engine")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("Engine", selection: $settings.translationEngine) {
                    ForEach(TranslationEngine.allCases) { engine in
                        Text(engine.displayName).tag(engine)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, VoxcribeTokens.Spacing.md)
            .padding(.bottom, VoxcribeTokens.Spacing.xs)
        }
    }

    // MARK: - TTS

    private var ttsSection: some View {
        SettingsCard {
            SettingsCardHeader(icon: "speaker.wave.2", title: "Text to Speech", color: .purple)

            SettingsRow {
                Label("Enable TTS", systemImage: "speaker.wave.2.fill")
                    .font(.subheadline)
                Spacer()
                Toggle("", isOn: $settings.ttsEnabled)
                    .labelsHidden()
                    .tint(.accentColor)
            }

            if settings.ttsEnabled {
                Divider().padding(.leading, 36)

                VStack(alignment: .leading, spacing: VoxcribeTokens.Spacing.sm) {
                    HStack {
                        Text("Speech Rate")
                            .font(.subheadline)
                        Spacer()
                        Text(rateLabel)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.quaternary))
                    }

                    HStack(spacing: VoxcribeTokens.Spacing.sm) {
                        Image(systemName: "tortoise.fill")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Slider(
                            value: $settings.ttsRate,
                            in: SettingsViewModel.ttsRateRange
                        )
                        .tint(.purple)
                        Image(systemName: "hare.fill")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, VoxcribeTokens.Spacing.md)
                .padding(.bottom, VoxcribeTokens.Spacing.xs)
            }
        }
        .animation(VoxcribeTokens.Animation.standard, value: settings.ttsEnabled)
    }

    private var rateLabel: String {
        let normalized = (settings.ttsRate - SettingsViewModel.ttsRateRange.lowerBound) /
            (SettingsViewModel.ttsRateRange.upperBound - SettingsViewModel.ttsRateRange.lowerBound)
        if normalized < 0.33 { return "Slow" }
        if normalized < 0.66 { return "Normal" }
        return "Fast"
    }

    // MARK: - Display

    private var displaySection: some View {
        SettingsCard {
            SettingsCardHeader(icon: "textformat.size", title: "Display", color: .green)

            SettingsRow {
                Label("Show Original", systemImage: "text.quote")
                    .font(.subheadline)
                Spacer()
                Toggle("", isOn: $settings.showOriginalText)
                    .labelsHidden()
                    .tint(.accentColor)
            }

            Divider().padding(.leading, 36)

            SettingsRow {
                Label("Show Partial Results", systemImage: "text.append")
                    .font(.subheadline)
                Spacer()
                Toggle("", isOn: $settings.showPartialResults)
                    .labelsHidden()
                    .tint(.accentColor)
            }

            Divider().padding(.leading, 36)

            VStack(alignment: .leading, spacing: VoxcribeTokens.Spacing.sm) {
                HStack {
                    Label("Font Size", systemImage: "textformat.size")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(settings.fontSize))pt")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(.quaternary))
                }

                HStack(spacing: VoxcribeTokens.Spacing.sm) {
                    Text("A")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    Slider(
                        value: $settings.fontSize,
                        in: SettingsViewModel.fontSizeRange,
                        step: 1
                    )
                    .tint(.green)
                    Text("A")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, VoxcribeTokens.Spacing.md)
            .padding(.bottom, VoxcribeTokens.Spacing.xs)

            Divider().padding(.leading, 36)

            VStack(alignment: .leading, spacing: VoxcribeTokens.Spacing.sm) {
                HStack {
                    Label("Silence Timeout", systemImage: "timer")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.1fs", settings.silenceTimeout))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(.quaternary))
                }

                Slider(
                    value: $settings.silenceTimeout,
                    in: SettingsViewModel.silenceTimeoutRange,
                    step: 0.5
                )
                .tint(.green)
            }
            .padding(.horizontal, VoxcribeTokens.Spacing.md)
            .padding(.bottom, VoxcribeTokens.Spacing.xs)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        SettingsCard {
            SettingsCardHeader(icon: "info.circle", title: "About", color: .gray)

            VStack(spacing: VoxcribeTokens.Spacing.sm) {
                HStack {
                    Text("Version")
                        .font(.subheadline)
                    Spacer()
                    Text("1.0")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                HStack {
                    Text("Powered by")
                        .font(.subheadline)
                    Spacer()
                    Text("Apple Frameworks")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, VoxcribeTokens.Spacing.md)
            .padding(.bottom, VoxcribeTokens.Spacing.xs)
        }
    }
}

// MARK: - Reusable Components

private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .background(
            RoundedRectangle(cornerRadius: VoxcribeTokens.CornerRadius.lg)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: VoxcribeTokens.CornerRadius.lg)
                        .strokeBorder(VoxcribeTokens.Colors.glassBorder, lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
    }
}

private struct SettingsCardHeader: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: VoxcribeTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(color.gradient)
                )

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, VoxcribeTokens.Spacing.md)
        .padding(.top, VoxcribeTokens.Spacing.md)
        .padding(.bottom, VoxcribeTokens.Spacing.sm)
    }
}

private struct SettingsRow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            content
        }
        .padding(.horizontal, VoxcribeTokens.Spacing.md)
        .padding(.vertical, VoxcribeTokens.Spacing.sm)
    }
}
