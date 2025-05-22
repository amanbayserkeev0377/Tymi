import SwiftUI

struct EmptyStateView: View {
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // App Icon
            Image("TymiBlank")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            Text("future_self_thank_you".localized)
                .font(.headline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
