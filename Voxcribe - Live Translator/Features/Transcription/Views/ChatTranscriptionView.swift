import SwiftUI

struct ChatTranscriptionView: View {
    let entries: [TranscriptionEntry]
    let currentPartialText: String
    let showOriginal: Bool
    let showPartial: Bool
    let fontSize: CGFloat
    let conversationMode: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: VoxcribeTokens.Spacing.lg) {
                    if entries.isEmpty && currentPartialText.isEmpty {
                        emptyState
                    }

                    ForEach(entries) { entry in
                        ChatBubbleView(
                            entry: entry,
                            showOriginal: showOriginal,
                            fontSize: fontSize,
                            conversationMode: conversationMode
                        )
                        .id(entry.id)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }

                    if showPartial && !currentPartialText.isEmpty {
                        PartialTextView(text: currentPartialText, fontSize: fontSize)
                            .id("partial")
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, VoxcribeTokens.Spacing.lg)
                .padding(.vertical, VoxcribeTokens.Spacing.md)
                .animation(VoxcribeTokens.Animation.smooth, value: entries.count)
            }
            .onChange(of: entries.count) {
                withAnimation(VoxcribeTokens.Animation.smooth) {
                    if let last = entries.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: currentPartialText) {
                if !currentPartialText.isEmpty {
                    withAnimation(VoxcribeTokens.Animation.smooth) {
                        proxy.scrollTo("partial", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: VoxcribeTokens.Spacing.md) {
            Image(systemName: "waveform.and.mic")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
                .symbolRenderingMode(.hierarchical)
            Text("Tap the microphone to start")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

// MARK: - Chat Bubble

private struct ChatBubbleView: View {
    let entry: TranscriptionEntry
    let showOriginal: Bool
    let fontSize: CGFloat
    let conversationMode: Bool

    private var isOutgoing: Bool {
        entry.speaker == .speakerA || entry.speaker == nil
    }

    private var speakerColor: Color {
        if conversationMode {
            return entry.speaker == .speakerB
                ? VoxcribeTokens.Colors.speakerB
                : VoxcribeTokens.Colors.speakerA
        }
        return VoxcribeTokens.Colors.accent
    }

    var body: some View {
        HStack(alignment: .bottom) {
            if !isOutgoing && conversationMode { Spacer(minLength: 50) }

            VStack(alignment: isOutgoing || !conversationMode ? .leading : .trailing, spacing: VoxcribeTokens.Spacing.sm) {
                // Speaker & language tag
                if conversationMode, let speaker = entry.speaker {
                    HStack(spacing: VoxcribeTokens.Spacing.xs) {
                        Circle()
                            .fill(speakerColor)
                            .frame(width: 8, height: 8)
                        Text("Speaker \(speaker.label)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(speakerColor)
                        Text("\(entry.sourceLanguage.flag) \(entry.sourceLanguage.shortName)")
                            .languagePill(color: speakerColor)
                    }
                }

                // Original text
                if showOriginal {
                    Text(entry.originalText)
                        .font(.system(size: fontSize))
                        .foregroundStyle(VoxcribeTokens.Colors.finalText)
                        .textSelection(.enabled)
                }

                // Translation
                if let translated = entry.translatedText {
                    Text(translated)
                        .font(.system(size: fontSize, weight: .medium))
                        .foregroundStyle(VoxcribeTokens.Colors.translatedText)
                        .textSelection(.enabled)
                } else if entry.isFinal {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Translating…")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Timestamp
                Text(entry.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, VoxcribeTokens.Spacing.md)
            .padding(.vertical, VoxcribeTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: VoxcribeTokens.CornerRadius.md)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: VoxcribeTokens.CornerRadius.md)
                            .strokeBorder(speakerColor.opacity(0.15), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            )

            if isOutgoing && conversationMode { Spacer(minLength: 50) }
        }
    }
}

// MARK: - Partial Text

private struct PartialTextView: View {
    let text: String
    let fontSize: CGFloat
    @State private var pulse = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: VoxcribeTokens.Spacing.xs) {
                HStack(spacing: VoxcribeTokens.Spacing.xs) {
                    Circle()
                        .fill(VoxcribeTokens.Colors.recording)
                        .frame(width: 6, height: 6)
                        .opacity(pulse ? 0.4 : 1.0)
                        .shadow(color: .red.opacity(0.5), radius: pulse ? 2 : 4)
                        .onAppear { pulse = true }
                        .animation(VoxcribeTokens.Animation.pulse, value: pulse)

                    Text("Listening…")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }

                Text(text)
                    .font(.system(size: fontSize))
                    .foregroundStyle(VoxcribeTokens.Colors.partialText)
                    .italic()
            }
            .padding(VoxcribeTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: VoxcribeTokens.CornerRadius.md)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: VoxcribeTokens.CornerRadius.md)
                            .strokeBorder(Color.orange.opacity(0.2), lineWidth: 0.5)
                    )
            )

            Spacer(minLength: 50)
        }
    }
}
