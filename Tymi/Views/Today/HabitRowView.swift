import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : .white
    }
    
    private var strokeColor: Color {
        colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray5)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("4 tasks to do")
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
