import SwiftUI
import SwiftData

struct DailyProgressRing: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    @Environment(\.colorScheme) private var colorScheme
    
    let date: Date
    @Query(filter: #Predicate<Habit> { !$0.isFreezed }, sort: \Habit.createdAt) private var baseHabits: [Habit]
    var iconSize: CGFloat = 64
    
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
    
    private var ringColors: [Color] {
        if isCompleted {
            return [
                Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1)),
                Color(#colorLiteral(red: 0.1803921569, green: 0.5450980392, blue: 0.3411764706, alpha: 1)),
                Color(#colorLiteral(red: 0.8196078431, green: 1, blue: 0.8352941176, alpha: 1)),
                Color(#colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)),
                Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1))
            ]
        } else {
            return [
                Color(#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)),
                Color(#colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.8805306554, blue: 0.5692787766, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.6470588235, blue: 0, alpha: 1)),
                Color(#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1))
            ]
        }
    }
    
    private var textColor: Color {
        if isCompleted {
            return colorScheme == .dark ?
            Color(#colorLiteral(red: 0.8196078431, green: 1, blue: 0.8352941176, alpha: 1)) :
            Color(#colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1))
        } else {
            return .primary
        }
    }
    
    // Проверка наличия привычек для выбранной даты
    private var hasHabitsForDate: Bool {
        return !activeHabitsForDate.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 24) {
            if hasHabitsForDate {
                // Показываем кольцо прогресса, если есть привычки для этого дня
                ZStack {
                    // Фоновый круг
                    Circle()
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 22)
                    
                    // Кольцо прогресса
                    Circle()
                        .trim(from: 0, to: completionPercentage)
                        .stroke(
                            AngularGradient(
                                colors: ringColors,
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            ),
                            style: StrokeStyle(
                                lineWidth: 22,
                                lineCap: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))
                    
                    // Текст в центре
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: iconSize, weight: .bold))
                            .foregroundStyle(textColor)
                    } else {
                        Text("\(Int(completionPercentage * 100))%")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(textColor)
                    }
                }
                .frame(width: 180, height: 180)
                .animation(.easeInOut(duration: 0.3), value: completionPercentage)
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
                .frame(height: 180)
                .padding(.horizontal, 20)
            }
        }
        .onChange(of: habitsUpdateService.lastUpdateTimestamp) { _, _ in
            
        }
    }
}
