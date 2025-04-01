import SwiftUI

struct TipCardView: View {
    let card: TipCard
    let namespace: Namespace.ID
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { proxy in
            let minX = proxy.frame(in: .global).minX
            let rotation = Double(minX - 32) / -28
            let scale = max(0.8, min(1, 1 - abs(Double(minX - 32) / 1000)))
            
            VStack(alignment: .leading, spacing: 20) {
                // Top row with icons
                HStack(spacing: 12) {
                    Image(systemName: card.icon)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 0.5))
                        )
                        .matchedGeometryEffect(id: "icon_\(card.id)", in: namespace)
                    
                    Spacer()
                    
                    // Additional icon for visual interest
                    Image(systemName: "swift")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 0.5))
                        )
                }
                
                Spacer()
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 8) {
                    Text(card.title)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                        .matchedGeometryEffect(id: "title_\(card.id)", in: namespace)
                    
                    Text(card.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineSpacing(4)
                        .lineLimit(3)
                        .matchedGeometryEffect(id: "subtitle_\(card.id)", in: namespace)
                }
                
                // Bottom metadata
                HStack {
                    Image(systemName: "clock")
                        .font(.footnote.weight(.medium))
                    Text("3 min read")
                        .font(.footnote.weight(.medium))
                    Spacer()
                }
                .foregroundStyle(.white.opacity(0.8))
            }
            .padding(30)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                ZStack {
                    LinearGradient(
                        colors: card.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Subtle pattern overlay
                    GeometryReader { proxy in
                        let size = proxy.size
                        Canvas { context, _ in
                            context.opacity = 0.1
                            for i in 0...10 {
                                for j in 0...10 {
                                    let x = CGFloat(i) * size.width / 10
                                    let y = CGFloat(j) * size.height / 10
                                    context.stroke(
                                        Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                                        with: .color(.white)
                                    )
                                }
                            }
                        }
                    }
                    
                    // Glass overlay
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .blendMode(.plusLighter)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(.white.opacity(0.3), lineWidth: 0.5)
            )
            .shadow(color: card.gradient[0].opacity(0.3), radius: 20, x: 0, y: 10)
            // 3D effects
            .rotation3DEffect(
                .degrees(rotation),
                axis: (x: 0, y: 1, z: 0),
                perspective: 1
            )
            .scaleEffect(scale)
            .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: minX)
            .matchedGeometryEffect(id: "container_\(card.id)", in: namespace)
        }
    }
}

