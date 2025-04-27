import SwiftUI
import SwiftData

struct DailyProgressRing: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var habitsUpdateService: HabitsUpdateService
    @Environment(\.colorScheme) private var colorScheme
    
    let date: Date
    @Query private var habits: [Habit]
    
    // MARK: - Computed Properties
    
    private var activeHabits: [Habit] {
        habits.filter { !$0.isArchived && $0.isActiveOnDate(date) }
    }
    
    private var completionPercentage: Double {
        guard !activeHabits.isEmpty else { return 0 }
        
        let totalPercentage = activeHabits.reduce(0.0) { sum, habit in
            sum + habit.completionPercentageForDate(date)
        }
        
        return totalPercentage / Double(activeHabits.count)
    }
    
    private var isCompleted: Bool {
        activeHabits.allSatisfy { $0.isCompletedForDate(date) }
    }
    
    private var isExceeded: Bool {
        activeHabits.allSatisfy { $0.isExceededForDate(date) }
    }
    
    private var ringColors: [Color] {
        if isExceeded {
            return colorScheme == .dark ? [
                Color(#colorLiteral(red: 0.2588235294, green: 0.3921568627, blue: 1, alpha: 1)),
                Color(#colorLiteral(red: 0.9222695707, green: 0.1548486791, blue: 0.2049736653, alpha: 1)),
                Color(#colorLiteral(red: 0.2588235294, green: 0.3921568627, blue: 1, alpha: 1))
            ] : [
                Color(#colorLiteral(red: 0.4408588113, green: 0.3927473914, blue: 1, alpha: 1)),
                Color(#colorLiteral(red: 0.9222695707, green: 0.1548486791, blue: 0.2049736653, alpha: 1)),
                Color(#colorLiteral(red: 0.4408588113, green: 0.3927473914, blue: 1, alpha: 1))
            ]
        } else if isCompleted {
            return colorScheme == .dark ? [
                Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1)),
                Color(#colorLiteral(red: 0.1803921569, green: 0.5450980392, blue: 0.3411764706, alpha: 1)),
                Color(#colorLiteral(red: 0.8196078431, green: 1, blue: 0.8352941176, alpha: 1)),
                Color(#colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)),
                Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1))
            ] : [
                Color(#colorLiteral(red: 0.2460050897, green: 0.606021149, blue: 0.1196907728, alpha: 1)),
                Color(#colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)),
                Color(#colorLiteral(red: 0.5960784314, green: 0.9843137255, blue: 0.5960784314, alpha: 1)),
                Color(#colorLiteral(red: 0, green: 0.459711194, blue: 0.3089413643, alpha: 1)),
                Color(#colorLiteral(red: 0.2460050897, green: 0.606021149, blue: 0.1196907728, alpha: 1))
            ]
        } else {
            return colorScheme == .dark ? [
                Color(#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)),
                Color(#colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.8805306554, blue: 0.5692787766, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.6470588235, blue: 0, alpha: 1)),
                Color(#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1))
            ] : [
                Color(#colorLiteral(red: 0.8246330492, green: 0.248637448, blue: 0.2358496644, alpha: 1)),
                Color(#colorLiteral(red: 0.9803921569, green: 0.446577528, blue: 0.02857491563, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.8419879334, blue: 0.3410575817, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.7249163399, blue: 0.1219073513, alpha: 1)),
                Color(#colorLiteral(red: 0.8246330492, green: 0.248637448, blue: 0.2358496644, alpha: 1))
            ]
        }
    }
    
    private var textColor: Color {
        if isExceeded {
            return colorScheme == .dark ?
            Color(#colorLiteral(red: 1, green: 0.3806057187, blue: 0.1013509959, alpha: 1)) :
            Color(#colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1))
        } else if isCompleted {
            return colorScheme == .dark ?
            Color(#colorLiteral(red: 0.8196078431, green: 1, blue: 0.8352941176, alpha: 1)) :
            Color(#colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1))
        } else {
            return .primary
        }
    }
    
    private var rotationAngle: Double {
        if isExceeded {
            return (completionPercentage - 1.0) * 360
        }
        return 0
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Фоновый круг
            Circle()
                .stroke(Color.secondary.opacity(0.1), lineWidth: 22)
            
            // Кольцо прогресса
            Circle()
                .trim(from: 0, to: isExceeded ? 1 : completionPercentage)
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
                .rotationEffect(.degrees(rotationAngle))
            
            // Текст в центре
            if isCompleted && !isExceeded {
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(textColor)
            } else {
                Text("\(Int(completionPercentage * 100))%")
                    .font(.system(size: 32, weight: .bold))
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
