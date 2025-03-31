import SwiftUI

struct GlassSectionBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let shadowOffset: CGFloat
    
    init(
        cornerRadius: CGFloat = 24,
        shadowRadius: CGFloat = 25,
        shadowOffset: CGFloat = -12
    ) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(colorScheme == .dark ? 
                .ultraThinMaterial.opacity(0.7) :
                .ultraThinMaterial.opacity(0.8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        colorScheme == .dark ?
                            Color.white.opacity(0.15) :
                            Color.white.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: colorScheme == .dark ?
                    .black.opacity(0.3) :
                    .black.opacity(0.2),
                radius: shadowRadius,
                x: 0,
                y: shadowOffset
            )
    }
} 