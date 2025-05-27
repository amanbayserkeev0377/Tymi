import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let date: Date
    let onTap: () -> Void
    
    private let ringSize: CGFloat = 54
    private let lineWidth: CGFloat = 6.5
    private let iconSize: CGFloat = 21
    
    private var adaptedFontSize: CGFloat {
        let value = habit.formattedProgressValue(for: date)
        let baseSize = ringSize * 0.32
        
        let digitsCount = value.filter { $0.isNumber }.count
        let factor: CGFloat = digitsCount <= 3 ? 1.0 : (digitsCount == 4 ? 0.85 : 0.7)
        
        return baseSize * factor
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.playSelection()
            onTap()
        }) {
            HStack(spacing: 12) {
                // Icon - увеличенная
                let iconName = habit.iconName ?? "checkmark"
                
                // Icon с pin overlay
                ZStack(alignment: .topTrailing) {
                    // Основная иконка
                    if iconName.hasPrefix("icon_") {
                        Image(iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .foregroundStyle(habit.iconColor.color)
                            .frame(width: 52, height: 52)
                            .background(
                                Circle()
                                    .fill(habit.iconColor.color.opacity(0.1))
                            )
                    } else {
                        Image(systemName: iconName)
                            .font(.system(size: 26))
                            .foregroundStyle(habit.iconName == nil ? AppColorManager.shared.selectedColor.color : habit.iconColor.color)
                            .frame(width: 52, height: 52)
                            .background(
                                Circle()
                                    .fill((habit.iconName == nil ? AppColorManager.shared.selectedColor.color : habit.iconColor.color).opacity(0.1))
                            )
                    }
                    
                    // Pin indicator как badge
                    if habit.isPinned {
                        Image(systemName: "pin")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(uiColor: .systemGray2))
                            .frame(width: 16, height: 16)
                    }
                }
                
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
        }
    }
}
