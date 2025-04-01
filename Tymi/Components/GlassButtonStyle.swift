import SwiftUI

struct GlassButtonStyle: ButtonStyle {
    let size: CGFloat
    
    init(size: CGFloat = 56) {
        self.size = size
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .frame(width: size, height: size)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
} 
