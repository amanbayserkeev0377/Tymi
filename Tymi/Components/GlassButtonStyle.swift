import SwiftUI

struct GlassButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    let size: CGFloat

    init(size: CGFloat = 46) {
        self.size = size
    }

    func makeBody(configuration: Configuration) -> some View {
        let strokeColor = colorScheme == .dark
            ? Color.white.opacity(0.2)
            : Color.black.opacity(0.2)

        return configuration.label
            .foregroundStyle(.primary)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(Color.clear)
                    .overlay(
                        Circle()
                            .strokeBorder(strokeColor, lineWidth: 1)
                    )
            )
            .contentShape(Circle())
            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.85 : 1)
            .animation(.easeInOut(duration: 0.3), value: configuration.isPressed)
            .environment(\.colorScheme, colorScheme)
    }
}
