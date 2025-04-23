import SwiftUI

struct ProgressControlSection: View {
    let habit: Habit
    @Binding var currentProgress: Int
    let completionPercentage: Double
    let formattedProgress: String
    
    var onIncrement: () -> Void
    var onDecrement: () -> Void
    
    @State private var progressValue: Int = 0
    
    private var isCompleted: Bool {
        completionPercentage >= 1.0
    }
    
    private var isExceeded: Bool {
        Double(currentProgress) > Double(habit.goal)
    }
    
    var body: some View {
        HStack(spacing: 40) {
            // minus
            Button(action: {
                progressValue -= 1
                onDecrement()
            }) {
                Image(systemName: "minus")
                    .font(.system(size: 30))
                    .tint(.primary)
            }
            .sensoryFeedback(.decrease, trigger: progressValue)
            
            // Progress Ring
            ProgressRing(
                progress: completionPercentage,
                currentValue: formattedProgress,
                isCompleted: isCompleted,
                isExceeded: isExceeded
            )
            
            // plus
            Button(action: {
                progressValue += 1
                onIncrement()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 30))
                    .tint(.primary)
            }
            .sensoryFeedback(.increase, trigger: progressValue)
        }
        .padding()
        .onAppear {
            progressValue = currentProgress
        }
        .onChange(of: currentProgress) { oldValue, newValue in
            progressValue = newValue
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Count habit
        ProgressControlSection(
            habit: Habit(title: "Push-ups", type: .count, goal: 20),
            currentProgress: .constant(10),
            completionPercentage: 0.5,
            formattedProgress: "10/20",
            onIncrement: {},
            onDecrement: {}
        )
        
        // Exceeded goal
        ProgressControlSection(
            habit: Habit(title: "Push-ups", type: .count, goal: 20),
            currentProgress: .constant(25),
            completionPercentage: 1.25,
            formattedProgress: "25/20",
            onIncrement: {},
            onDecrement: {}
        )
        
        // Time habit
        ProgressControlSection(
            habit: Habit(title: "Meditation", type: .time, goal: 3600),
            currentProgress: .constant(1800),
            completionPercentage: 0.5,
            formattedProgress: "0:30:00",
            onIncrement: {},
            onDecrement: {}
        )
    }
    .padding()
}
