import SwiftUI

struct EmptyStateView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            // arrow animation
            LottieView(animationName: colorScheme == .dark ? "arrow_dark" : "arrow_light",
                       loopMode: .loop
            )
            .frame(width: 180, height: 180)
            .rotationEffect(.degrees(45))
            .offset(x: 20, y: 10)
            
            Text("Your future self will thank you.")
                .font(.title2)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassCard()
    }
}
