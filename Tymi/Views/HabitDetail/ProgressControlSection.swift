import SwiftUI

struct ProgressControlSection: View {
    let habit: Habit
    @Binding var currentProgress: Int
    let completionPercentage: Double
    let formattedProgress: String
    
    var onIncrement: () -> Void
    var onDecrement: () -> Void
    
    @State private var incrementTrigger: Bool = false
    @State private var decrementTrigger: Bool = false
    
    // Определяем, является ли устройство маленьким (iPhone SE)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isSmallDevice: Bool {
        UIScreen.main.bounds.width <= 375 // iPhone SE, iPhone 8
    }
    
    private var isCompleted: Bool {
        completionPercentage >= 1.0
    }
    
    private var isExceeded: Bool {
        Double(currentProgress) > Double(habit.goal)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                decrementTrigger.toggle()
                onDecrement()
            }) {
                Image(systemName: "minus")
                    .font(.system(size: isSmallDevice ? 22 : 24))
                    .frame(minWidth: 44, minHeight: 44)
                    .background(
                        Circle()
                            .fill(AppColorManager.shared.selectedColor.color.opacity(0.1))
                    )
            }
            .decreaseHaptic(trigger: decrementTrigger)
            .padding(.leading, isSmallDevice ? 18 : 22) // Уменьшаем отступ для маленьких экранов
            
            Spacer()
            
            // Адаптивный размер для кольца прогресса
            ProgressRing(
                progress: completionPercentage,
                currentValue: formattedProgress,
                isCompleted: isCompleted,
                isExceeded: isExceeded,
                size: isSmallDevice ? 160 : 180 // Уменьшаем размер для маленьких экранов
            )
            .aspectRatio(1, contentMode: .fit)
            
            Spacer()
            
            Button(action: {
                incrementTrigger.toggle()
                onIncrement()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: isSmallDevice ? 22 : 24))
                    .frame(minWidth: 44, minHeight: 44)
                    .background(
                        Circle()
                            .fill(AppColorManager.shared.selectedColor.color.opacity(0.1))
                    )
            }
            .increaseHaptic(trigger: incrementTrigger)
            .padding(.trailing, isSmallDevice ? 18 : 22) // Уменьшаем отступ для маленьких экранов
        }
        .padding(.horizontal, isSmallDevice ? 8 : 16) // Уменьшаем горизонтальные отступы
    }
}
