import SwiftUI

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func glassCard() -> some View {
        self.modifier(GlassCard())
    }
}
