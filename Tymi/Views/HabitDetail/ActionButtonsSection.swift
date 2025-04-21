import SwiftUI

struct ActionButtonsSection: View {
    let habit: Habit
    let isTimerRunning: Bool
    let hourglassRotation: Double
    
    var onReset: () -> Void
    var onTimerToggle: () -> Void
    var onManualEntry: () -> Void
    
    var body: some View {
        HStack(spacing: 32) {
            // Reset value
            Button(action: onReset) {
                Image(systemName: "hourglass.bottomhalf.filled")
                    .font(.system(size: 24))
                    .tint(.primary)
            }
            
            // Timer or manual entry button
            Button(action: onTimerToggle) {
                if habit.type == .time {
                    Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 44))
                        .tint(.primary)
                } else {
                    Image(systemName: "plus.arrow.trianglehead.clockwise")
                        .font(.system(size: 24))
                        .tint(.primary)
                }
            }
            
            // Manual entry for Time type habits
            if habit.type == .time {
                Button(action: onManualEntry) {
                    Image(systemName: "hourglass.tophalf.filled")
                        .font(.system(size: 24))
                        .tint(.primary)
                        .rotationEffect(.degrees(hourglassRotation))
                }
            }
        }
        .padding(.bottom, 40)
    }
}

#Preview {
    HStack {
        // For Count habit
        ActionButtonsSection(
            habit: Habit(title: "Отжимания", type: .count, goal: 20),
            isTimerRunning: false,
            hourglassRotation: 0,
            onReset: {},
            onTimerToggle: {},
            onManualEntry: {}
        )
        
        // For Time habit
        ActionButtonsSection(
            habit: Habit(title: "Медитация", type: .time, goal: 3600),
            isTimerRunning: false,
            hourglassRotation: 0,
            onReset: {},
            onTimerToggle: {},
            onManualEntry: {}
        )
    }
    .padding()
}
