import SwiftUI
import SwiftData

struct DailyProgressRing: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    @Environment(\.colorScheme) private var colorScheme
    
    let date: Date
    @Query(sort: \Habit.createdAt)
    private var baseHabits: [Habit]
    
    // Размер кольца с разумными значениями по умолчанию
    var size: CGFloat = 180
    
    // MARK: - Computed Properties
    
    private var activeHabitsForDate: [Habit] {
        baseHabits.filter { $0.isActiveOnDate(date) && date >= $0.startDate }
    }
    
    private var completionPercentage: Double {
        guard !activeHabitsForDate.isEmpty else { return 0 }
        
        let totalPercentage = activeHabitsForDate.reduce(0.0) { sum, habit in
            sum + habit.completionPercentageForDate(date)
        }
        
        return totalPercentage / Double(activeHabitsForDate.count)
    }
    
    private var isCompleted: Bool {
        activeHabitsForDate.allSatisfy { $0.isCompletedForDate(date) } && !activeHabitsForDate.isEmpty
    }
    
    // Проверка наличия привычек для выбранной даты
    private var hasHabitsForDate: Bool {
        return !activeHabitsForDate.isEmpty
    }
    
    // Адаптивный размер для разных устройств, но с фиксированными значениями
    private var adaptiveSize: CGFloat {
        // Получаем ширину экрана
        let screenWidth = UIScreen.main.bounds.width
        
        // Для iPhone SE и маленьких устройств
        if screenWidth <= 320 {
            return 150
        }
        // Для iPhone 8, XR, 11 и подобных
        else if screenWidth <= 414 {
            return 170
        }
        // Для больших iPhone
        else if screenWidth <= 428 {
            return 180
        }
        // Для iPad и больших устройств
        else {
            return 200
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 24) {
            if hasHabitsForDate {
                // Используем улучшенный ProgressRing с фиксированным размером
                ProgressRing(
                    progress: completionPercentage,
                    currentValue: "\(Int(completionPercentage * 100))%",
                    isCompleted: isCompleted,
                    isExceeded: false, // Для DailyProgressRing нет концепции "перевыполнение"
                    size: adaptiveSize
                )
                .accessibilityLabel("daily_progress".localized)
                .accessibilityValue(isCompleted
                    ? "all_habits_completed".localized
                    : "completion_percent".localized(with: Int(completionPercentage * 100)))
            } else {
                // Сообщение, когда нет активных привычек
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("no_habits_for_date".localized)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("try_different_date".localized)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .frame(height: adaptiveSize)
                .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: habitsUpdateService.lastUpdateTimestamp) { _, _ in }
    }
}

#Preview {
    DailyProgressRing(date: Date())
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
