import SwiftUI

struct StreaksView: View {
    let viewModel: HabitStatsViewModel
    
    var body: some View {
        HStack {
            Image(systemName: "laurel.leading")
                .font(.system(size: 38))
                .foregroundColor(.secondary)
            VStack {
                Text("\(viewModel.currentStreak)")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.primary)
                Text("Streak")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            VStack {
                Text("\(viewModel.bestStreak)")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.primary)
                Text("Best")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            VStack {
                Text("\(viewModel.totalValue)")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.primary)
                Text("Total")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            Image(systemName: "laurel.trailing")
                .font(.system(size: 38))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
} 
