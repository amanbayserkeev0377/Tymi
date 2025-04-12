import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : .white
    }
    
    private var strokeColor: Color {
        colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray4)
    }
    
    private var goalText: String {
        if habit.type == .count {
            return "\(Int(habit.goal.doubleValue))"
        } else {
            let hours = Int(habit.goal.doubleValue) / 3600
            let minutes = Int(habit.goal.doubleValue) / 60 % 60
            
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("\(goalText)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(strokeColor, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        HabitRowView(habit: Habit(name: "Getting Started"))
        HabitRowView(habit: Habit(name: "Daily Exercise"))
        HabitRowView(habit: Habit(name: "Read a Book"))
    }
    .padding()
}
