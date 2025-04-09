import SwiftUI

struct HabitRowView: View {
    let habit: Habit

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                
                Text(goalText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    private var goalText: String {
        switch habit.type {
        case .count:
            return "\(Int(habit.goal))"
        case .time:
            let hours = Int(habit.goal) / 3600
            let minutes = Int(habit.goal) / 60 % 60
            return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
        }
    }
}
