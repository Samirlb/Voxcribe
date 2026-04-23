import SwiftUI

extension View {
    func languagePill(color: Color = .accentColor) -> some View {
        modifier(LanguagePillStyle(color: color))
    }

    func chatBubble(isOutgoing: Bool) -> some View {
        modifier(ChatBubbleModifier(isOutgoing: isOutgoing))
    }

    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
