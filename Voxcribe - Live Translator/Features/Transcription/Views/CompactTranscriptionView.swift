#if os(macOS)
import SwiftUI

struct CompactTranscriptionView: View {
    let entries: [TranscriptionEntry]
    let currentPartialText: String
    let audioLevel: Float
    let isListening: Bool
    let onToggleListening: () -> Void
    let onSwapLanguages: () -> Void

    var body: some View {
        HStack(spacing: VoxcribeTokens.Spacing.md) {
            // Record button
            Button(action: onToggleListening) {
                Image(systemName: isListening ? "stop.fill" : "mic.fill")
                    .font(.title3)
                    .foregroundStyle(isListening ? .red : .accentColor)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            AudioLevelIndicator(level: audioLevel, barCount: 3)

            Divider()
                .frame(height: 24)

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                if let lastEntry = entries.last {
                    if let translated = lastEntry.translatedText {
                        Text(translated)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(VoxcribeTokens.Colors.translatedText)
                            .lineLimit(1)
                    }

                    Text(lastEntry.originalText)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if !currentPartialText.isEmpty {
                    Text(currentPartialText)
                        .font(.system(size: 13))
                        .foregroundStyle(VoxcribeTokens.Colors.partialText)
                        .italic()
                        .lineLimit(1)
                } else {
                    Text(isListening ? "Listening..." : "Press to start")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Swap button
            Button(action: onSwapLanguages) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, VoxcribeTokens.Spacing.md)
        .padding(.vertical, VoxcribeTokens.Spacing.sm)
        .frame(height: 44)
    }
}
#endif
