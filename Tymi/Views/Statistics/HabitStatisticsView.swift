import SwiftUI
import SwiftData

// Временная заглушка для статистики привычки
struct HabitStatisticsView: View {
    let habit: Habit
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Статистика для привычки \(habit.title)")
                    .font(.headline)
                    .padding()
                
                Text("В следующих обновлениях здесь появится подробная статистика выполнения привычки по дням, неделям и месяцам")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("habit_statistics".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("close".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}
