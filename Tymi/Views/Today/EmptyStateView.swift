import SwiftUI

struct EmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // App Icon
            Image("Tymi_blank")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            Text("future_self_thank_you".localized)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        TodayViewBackground()
        EmptyStateView()
    }
}
