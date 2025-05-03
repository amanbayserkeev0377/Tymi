import SwiftUI

struct StatisticsSection: View {
    // MARK: - Properties
    let currentStreak: Int
    let bestStreak: Int
    let totalCompletions: Int
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    var body: some View {
        HStack {
            Image(systemName: "laurel.leading")
                .font(.system(size: 50))
                .foregroundStyle(.tertiary)
            
            StatisticCard(
                title: "current_streak".localized,
                value: "\(currentStreak)",
                symbolName: "flame.fill"
            )
            
            StatisticCard(
                title: "best_streak".localized,
                value: "\(bestStreak)",
                symbolName: "trophy"
            )
            
            StatisticCard(
                title: "total_completions".localized,
                value: "\(totalCompletions)",
                symbolName: "checkmark"
            )
            
            Image(systemName: "laurel.trailing")
                .font(.system(size: 50))
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - StatisticCard
private struct StatisticCard: View {
    let title: String
    let value: String
    let symbolName: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            HStack(spacing: 4) {
                Text(title)
                    .foregroundStyle(.secondary)
                Image(systemName: symbolName)
                    .foregroundStyle(.primary)
            }
            .font(.caption)
            
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    VStack {
        StatisticsSection(
            currentStreak: 5,
            bestStreak: 10,
            totalCompletions: 42
        )
    }
    .padding()
}
