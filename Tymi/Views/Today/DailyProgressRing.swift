import SwiftUI
import SwiftData

struct DailyProgressRing: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var habitsUpdateService: HabitsUpdateService
    @Environment(\.colorScheme) private var colorScheme
    
    let date: Date
    @Query private var habits: [Habit]
    var iconSize: CGFloat = 64
    
    // MARK: - Computed Properties
    
    private var activeHabitsForDate: [Habit] {
        habits.filter { !$0.isFreezed && $0.isActiveOnDate(date) }
    }
    
    private var completionPercentage: Double {
        guard !activeHabitsForDate.isEmpty else { return 0 }
        
        let totalPercentage = activeHabitsForDate.reduce(0.0) { sum, habit in
            sum + habit.completionPercentageForDate(date)
        }
        
        return totalPercentage / Double(activeHabitsForDate.count)
    }
    
    private var isCompleted: Bool {
        activeHabitsForDate.allSatisfy { $0.isCompletedForDate(date) }
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
    
    // MARK: - Body
    
    var body: some View {
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
        .onChange(of: habitsUpdateService.lastUpdateTimestamp) { _, _ in
            // Обновление не требуется, так как @Query автоматически обновит данные
        }
    }
}

#Preview {
    VStack {
        DailyProgressRing(date: Date())
            .preferredColorScheme(.light)
        
        DailyProgressRing(date: Date())
            .preferredColorScheme(.dark)
    }
    .padding()
    .background(TodayViewBackground())
    .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
    .environmentObject(HabitsUpdateService())
} 
