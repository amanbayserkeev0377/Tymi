import SwiftUI

struct EmptyStateView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Spacer()
            
            
            VStack(spacing: 20) {
                // arrow animation
                LottieView(
                    animationName: colorScheme == .dark ? "arrow_dark" : "arrow_light",
                           loopMode: .loop
                )
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(45))
                .offset(x: 24, y: 10)
                
                Text("Your future self will thank you.")
                    .font(.title3)
                    .fontWeight(.medium)
            }
            .padding()
            .glassCard()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
