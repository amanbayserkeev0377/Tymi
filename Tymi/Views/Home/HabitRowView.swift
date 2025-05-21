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
    
    // MARK: - Computed Properties
    private let ringSize: CGFloat = 50
    private let lineWidth: CGFloat = 6.5
    private let iconSize: CGFloat = 22
    
    private var adaptedFontSize: CGFloat {
        let value = habit.formattedProgressValue(for: date)
        let baseSize = ringSize * 0.3
        
        let digitsCount = value.filter { $0.isNumber }.count
        
        let factor: CGFloat
        switch digitsCount {
        case 0...3: // 1, 12, 123, 999
            factor = 1.0
        case 4: // 1000, 1 000, 9999
            factor = 0.9
        case 5: // 10000, 10 000, 99999
            factor = 0.75
        case 6: // 100000, 100 000, 999999
            factor = 0.60
        default: // Более длинные строки
            factor = 0.5
        }
        
        return baseSize * factor
    }
    
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
                    .lineLimit(1)
                
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
                size: ringSize,
                lineWidth: lineWidth,
                fontSize: adaptedFontSize,
                iconSize: iconSize
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
                try? await Task.sleep(for: .milliseconds(100))
                withAnimation {
                    isPressed = false
                }
                onTap?()
            }
        }
    }
}
