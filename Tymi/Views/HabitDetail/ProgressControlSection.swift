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
    
    private var isCompleted: Bool {
        completionPercentage >= 1.0
    }
    
    private var isExceeded: Bool {
        Double(currentProgress) > Double(habit.goal)
    }
    
    var body: some View {
        HStack {
            // Контейнер для кнопки минус
            Button(action: {
                decrementTrigger.toggle()
                onDecrement()
            }) {
                Image(systemName: "minus")
                    .font(.system(size: 24))
                    .frame(minWidth: 44, minHeight: 44)
                    .background(
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                    )
            }
            .decreaseHaptic(trigger: decrementTrigger)
            
            Spacer()
            
            // Центральный элемент - кольцо прогресса
            ProgressRing(
                progress: completionPercentage,
                currentValue: formattedProgress,
                isCompleted: isCompleted,
                isExceeded: isExceeded
            )
            .aspectRatio(1, contentMode: .fit)
            
            Spacer()
            
            // Контейнер для кнопки плюс
            Button(action: {
                incrementTrigger.toggle()
                onIncrement()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                    .frame(minWidth: 44, minHeight: 44)
                    .background(
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                    )
            }
            .increaseHaptic(trigger: incrementTrigger)
        }
        .padding(.horizontal)
    }
}
