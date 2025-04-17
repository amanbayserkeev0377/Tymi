import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let date: Date
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.headline)
                
                Text(habit.formattedProgress(for: date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            ProgressCircle(
                progress: habit.completionPercentageForDate(date),
                isCompleted: habit.isCompletedForDate(date)
            )
        }
        .padding(.vertical, 8)
    }
}
