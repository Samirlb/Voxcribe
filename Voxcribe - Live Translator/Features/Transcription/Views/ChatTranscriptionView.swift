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
                LazyVStack(spacing: VoxcribeTokens.Spacing.md) {
                    ForEach(entries) { entry in
                        ChatBubbleView(
                            entry: entry,
                            showOriginal: showOriginal,
                            fontSize: fontSize,
                            conversationMode: conversationMode
                        )
                        .id(entry.id)
                    }

                    if showPartial && !currentPartialText.isEmpty {
                        PartialTextView(text: currentPartialText, fontSize: fontSize)
                            .id("partial")
                    }
                }
                .padding(.horizontal, VoxcribeTokens.Spacing.lg)
                .padding(.vertical, VoxcribeTokens.Spacing.sm)
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

    private var bubbleColor: Color {
        if conversationMode {
            return entry.speaker == .speakerA
                ? VoxcribeTokens.Colors.speakerA
                : VoxcribeTokens.Colors.speakerB
        }
        return VoxcribeTokens.Colors.accent
    }

    var body: some View {
        HStack {
            if !isOutgoing { Spacer(minLength: 40) }

            VStack(alignment: isOutgoing ? .leading : .trailing, spacing: VoxcribeTokens.Spacing.xs) {
                if conversationMode, let speaker = entry.speaker {
                    HStack(spacing: VoxcribeTokens.Spacing.xs) {
                        Text("Speaker \(speaker.label)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                        Text(entry.sourceLanguage.displayName)
                            .languagePill(color: bubbleColor)
                    }
                }

                if showOriginal {
                    Text(entry.originalText)
                        .font(.system(size: fontSize))
                        .foregroundStyle(VoxcribeTokens.Colors.finalText)
                }

                if let translated = entry.translatedText {
                    Text(translated)
                        .font(.system(size: fontSize))
                        .fontWeight(.medium)
                        .foregroundStyle(VoxcribeTokens.Colors.translatedText)
                } else if entry.isFinal {
                    ProgressView()
                        .controlSize(.small)
                }

                Text(entry.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .chatBubble(isOutgoing: isOutgoing)

            if isOutgoing { Spacer(minLength: 40) }
        }
    }
}

// MARK: - Partial Text

private struct PartialTextView: View {
    let text: String
    let fontSize: CGFloat

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: VoxcribeTokens.Spacing.xs) {
                HStack(spacing: VoxcribeTokens.Spacing.xs) {
                    Circle()
                        .fill(VoxcribeTokens.Colors.recording)
                        .frame(width: 6, height: 6)
                    Text("Listening...")
                        .font(.caption2)
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
                    .fill(Color.secondary.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: VoxcribeTokens.CornerRadius.md)
                            .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
            )

            Spacer(minLength: 40)
        }
    }
}
