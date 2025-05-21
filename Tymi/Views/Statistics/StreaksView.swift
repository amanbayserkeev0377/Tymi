import SwiftUI

struct StreaksView: View {
    let viewModel: HabitStatsViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            // Левый лавровый венок
            Image(systemName: "laurel.leading")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
                .accessibility(hidden: true)
            
            // Три колонки статистики
            Group {
                // Текущая серия
                StatColumn(
                    value: "\(viewModel.currentStreak)",
                    label: "streak".localized
                )
                
                // Лучшая серия
                StatColumn(
                    value: "\(viewModel.bestStreak)",
                    label: "best".localized
                )
                
                // Всего
                StatColumn(
                    value: "\(viewModel.totalValue)",
                    label: "total".localized
                )
            }
            
            // Правый лавровый венок
            Image(systemName: "laurel.trailing")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
                .accessibility(hidden: true)
        }
        .padding(.vertical, 8)
        .id("streaks-\(viewModel.currentStreak)-\(viewModel.bestStreak)-\(viewModel.totalValue)")
    }
}

// Выделяем колонку статистики в отдельный компонент
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
