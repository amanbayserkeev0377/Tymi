import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let date: Date
    var onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.title)
                    .font(.headline)
                
                Text("Goal: \(habit.formattedGoal)".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            ProgressRing(
                progress: habit.completionPercentageForDate(date),
                currentValue: habit.formattedProgressValue(for: date),
                isCompleted: habit.isCompletedForDate(date),
                isExceeded: habit.isExceededForDate(date),
                size: 50,
                lineWidth: 6.5,
                fontSize: 13,
                iconSize: 22
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.black.opacity(0.25) : Color.white.opacity(0.8))
                .shadow(color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1),
                        radius: isPressed ? 2 : 4, x: 0, y: isPressed ? 1 : 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            colorScheme == .dark
                            ? Color.gray.opacity(0.05)
                            : Color.gray.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .padding(.horizontal)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
                onTap()
            }
        }
    }
}

#Preview {
    VStack {
        HabitRowView(
            habit: Habit(title: "Утренняя зарядка", type: .count, goal: 20),
            date: Date(),
            onTap: {}
        )
        .preferredColorScheme(.light)
        
        HabitRowView(
            habit: Habit(title: "Медитация", type: .time, goal: 3600),
            date: Date(),
            onTap: {}
        )
        .preferredColorScheme(.dark)
    }
    .padding()
    .background(TodayViewBackground())
}
