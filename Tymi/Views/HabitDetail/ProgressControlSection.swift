import SwiftUI

struct ProgressControlSection: View {
    let habit: Habit
    @Binding var currentProgress: Int
    let completionPercentage: Double
    let formattedProgress: String
    
    var onIncrement: () -> Void
    var onDecrement: () -> Void
    
    var body: some View {
        HStack(spacing: 40) {
            // minus
            Button(action: onDecrement) {
                Image(systemName: "minus")
                    .font(.system(size: 32))
                    .tint(.primary)
            }
            
            // Progress Ring
            ProgressRing(
                progress: completionPercentage,
                currentValue: formattedProgress
            )
            
            // plus
            Button(action: onIncrement) {
                Image(systemName: "plus")
                    .font(.system(size: 32))
                    .tint(.primary)
            }
        }
        .padding()
    }
}

#Preview {
    VStack(spacing: 20) {
        // Count habit
        ProgressControlSection(
            habit: Habit(title: "Отжимания", type: .count, goal: 20),
            currentProgress: .constant(10),
            completionPercentage: 0.5,
            formattedProgress: "10/20",
            onIncrement: {},
            onDecrement: {}
        )
        
        // Time habit
        ProgressControlSection(
            habit: Habit(title: "Медитация", type: .time, goal: 3600),
            currentProgress: .constant(1800),
            completionPercentage: 0.5,
            formattedProgress: "0:30:00",
            onIncrement: {},
            onDecrement: {}
        )
    }
    .padding()
}
