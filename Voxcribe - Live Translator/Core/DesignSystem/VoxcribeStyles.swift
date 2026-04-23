import SwiftUI

struct RecordButtonStyle: ButtonStyle {
    let isRecording: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .foregroundStyle(.white)
            .frame(width: 64, height: 64)
            .background(
                Circle()
                    .fill(isRecording ? VoxcribeTokens.Colors.recording : VoxcribeTokens.Colors.accent)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(VoxcribeTokens.Animation.quick, value: configuration.isPressed)
    }
}

struct LanguagePillStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, VoxcribeTokens.Spacing.sm)
            .padding(.vertical, VoxcribeTokens.Spacing.xs)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
            .foregroundStyle(color)
    }
}

struct ChatBubbleModifier: ViewModifier {
    let isOutgoing: Bool

    func body(content: Content) -> some View {
        content
            .padding(VoxcribeTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: VoxcribeTokens.CornerRadius.md)
                    .fill(isOutgoing
                          ? VoxcribeTokens.Colors.accent.opacity(0.12)
                          : VoxcribeTokens.Colors.secondaryBackground)
            )
    }
}

struct AudioLevelIndicator: View {
    let level: Float
    let barCount: Int

    init(level: Float, barCount: Int = 5) {
        self.level = level
        self.barCount = barCount
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                let threshold = Float(index) / Float(barCount)
                RoundedRectangle(cornerRadius: 2)
                    .fill(level > threshold ? VoxcribeTokens.Colors.accent : Color.gray.opacity(0.3))
                    .frame(width: 4, height: CGFloat(8 + index * 4))
            }
        }
        .animation(VoxcribeTokens.Animation.quick, value: level)
    }
}
