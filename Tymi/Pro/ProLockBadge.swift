import SwiftUI

struct ProLockBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundStyle(.white)
            
            Text("PRO")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(ProGradientColors.proGradientSimple)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
