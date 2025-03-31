import SwiftUI

struct GlassSectionBackground<Content: View>: View {
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let shadowOffset: CGFloat
    let content: Content
    
    init(
        cornerRadius: CGFloat = 24,
        shadowRadius: CGFloat = 25,
        shadowOffset: CGFloat = -12,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
        self.content = content()
    }
    
    var body: some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.background)
                    .background {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    }
                    .shadow(
                        color: .black.opacity(0.2),
                        radius: shadowRadius,
                        x: 0,
                        y: shadowOffset
                    )
            }
    }
} 