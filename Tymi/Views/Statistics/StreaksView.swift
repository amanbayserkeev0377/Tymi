import SwiftUI

struct StreaksView: View {
    let viewModel: HabitStatsViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "laurel.leading")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
                .accessibility(hidden: true)
            
            Group {
                // Streak
                StatColumn(
                    value: "\(viewModel.currentStreak)",
                    label: "streak".localized
                )
                
                // Best
                StatColumn(
                    value: "\(viewModel.bestStreak)",
                    label: "best".localized
                )
                
                // Total
                StatColumn(
                    value: "\(viewModel.totalValue)",
                    label: "total".localized
                )
            }
            
            Image(systemName: "laurel.trailing")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
                .accessibility(hidden: true)
        }
        .padding(.vertical, 8)
    }
}

struct StatColumn: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
