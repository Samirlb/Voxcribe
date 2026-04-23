import SwiftUI

struct RecordButtonStyle: ButtonStyle {
    let isRecording: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(width: 60, height: 60)
            .background(
                Circle()
                    .fill(
                        isRecording
                            ? AnyShapeStyle(Color.red.gradient)
                            : AnyShapeStyle(Color.accentColor.gradient)
                    )
                    .shadow(color: (isRecording ? Color.red : Color.accentColor).opacity(0.4), radius: isRecording ? 12 : 6, y: 2)
            )
            .overlay(
                Circle()
                    .strokeBorder(.white.opacity(0.25), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(VoxcribeTokens.Animation.quick, value: configuration.isPressed)
    }
}

struct LanguagePillStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, VoxcribeTokens.Spacing.sm)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(color.opacity(0.2))
                    .overlay(
                        Capsule()
                            .strokeBorder(color.opacity(0.3), lineWidth: 0.5)
                    )
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
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: VoxcribeTokens.CornerRadius.md)
                            .strokeBorder(
                                isOutgoing
                                    ? VoxcribeTokens.Colors.speakerA.opacity(0.2)
                                    : VoxcribeTokens.Colors.glassBorder,
                                lineWidth: 0.5
                            )
                    )
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
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                let threshold = Float(index) / Float(barCount)
                let isActive = level > threshold
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(isActive ? VoxcribeTokens.Colors.accent : Color.gray.opacity(0.25))
                    .frame(width: 3, height: CGFloat(6 + index * 3))
                    .animation(VoxcribeTokens.Animation.quick, value: level)
            }
        }
    }
}

// MARK: - Glass Card Modifier

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = VoxcribeTokens.CornerRadius.lg

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(VoxcribeTokens.Colors.glassBorder, lineWidth: 0.5)
                    )
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = VoxcribeTokens.CornerRadius.lg) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}
