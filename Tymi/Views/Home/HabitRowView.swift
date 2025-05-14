import SwiftUI

struct HabitRowView: View {
    // MARK: - Properties
    let habit: Habit
    let date: Date
    var onTap: (() -> Void)? = nil
    
    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - State
    @State private var isPressed = false
    
    var body: some View {
        HStack {
            if let iconName = habit.iconName {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 30, height: 30)
                    .padding(.trailing, 8)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.title)
                    .font(.headline)
                
                Text("goal_format".localized(with: habit.formattedGoal))
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
                fontSize: 16,
                iconSize: 22
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white)
                .shadow(color: colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2),
                        radius: isPressed ? 2 : 4, x: 0, y: isPressed ? 1 : 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            colorScheme == .dark
                            ? Color.white.opacity(0.1)
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
            
            Task {
                try? await Task.sleep(for: .seconds(0.1))
                if !Task.isCancelled {
                    await MainActor.run {
                        withAnimation {
                            isPressed = false
                        }
                        onTap?()
                    }
                }
            }
        }
    }
}
