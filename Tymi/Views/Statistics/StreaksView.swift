import SwiftUI

struct StreaksView: View {
    let viewModel: HabitStatsViewModel
    
    var body: some View {
        HStack {
            Image(systemName: "laurel.leading")
                .font(.system(size: 42))
                .foregroundColor(.secondary)
            VStack {
                Text("\(viewModel.currentStreak)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                Text("streak".localized)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            VStack {
                Text("\(viewModel.bestStreak)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                Text("best".localized)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            VStack {
                Text("\(viewModel.totalValue)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                Text("total".localized)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            Image(systemName: "laurel.trailing")
                .font(.system(size: 42))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .id("streaks-\(viewModel.currentStreak)-\(viewModel.bestStreak)-\(viewModel.totalValue)")
    }
} 
