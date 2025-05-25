import SwiftUI

// MARK: - Native Habit Row (простая нативная строка)
struct HabitRowNative: View {
    let habit: Habit
    let date: Date
    let onTap: () -> Void
    
    private let ringSize: CGFloat = 44
    private let lineWidth: CGFloat = 5.5
    private let iconSize: CGFloat = 18
    
    private var adaptedFontSize: CGFloat {
        let value = habit.formattedProgressValue(for: date)
        let baseSize = ringSize * 0.32
        
        let digitsCount = value.filter { $0.isNumber }.count
        let factor: CGFloat = digitsCount <= 3 ? 1.0 : (digitsCount == 4 ? 0.85 : 0.7)
        
        return baseSize * factor
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Pin indicator
                if habit.isPinned {
                    Image(systemName: "pin")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 12)
                } else {
                    Spacer()
                        .frame(width: 12)
                }
                
                // Icon
                Image(systemName: habit.iconName ?? "checkmark")
                    .font(.title3)
                    .foregroundStyle(habit.iconName == nil ? .accentColor : habit.iconColor.color)
                    .frame(width: 28, height: 28)
                
                // Title and goal
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text("goal_format".localized(with: habit.formattedGoal))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Progress ring
                ProgressRing(
                    progress: habit.completionPercentageForDate(date),
                    currentValue: habit.formattedProgressValue(for: date),
                    isCompleted: habit.isCompletedForDate(date),
                    isExceeded: habit.isExceededForDate(date),
                    size: ringSize,
                    lineWidth: lineWidth,
                    fontSize: adaptedFontSize,
                    iconSize: iconSize
                )
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
