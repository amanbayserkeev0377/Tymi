import SwiftUI

struct ActionButtonsSection: View {
    let habit: Habit
    let isTimerRunning: Bool
    
    var onReset: () -> Void
    var onTimerToggle: () -> Void
    var onManualEntry: () -> Void
    
    @State private var resetPressed = false
    @State private var togglePressed = false
    @State private var manualEntryPressed = false
    
    var body: some View {
        HStack(spacing: 32) {
            // Reset button - используем .error
            Button(action: {
                resetPressed.toggle()
                onReset()
            }) {
                Image(systemName: "minus.arrow.trianglehead.counterclockwise")
                    .font(.system(size: 24))
                    .tint(.primary)
            }
            .errorHaptic(trigger: resetPressed)
            
            // Timer/Toggle button
            Button(action: {
                togglePressed.toggle()
                onTimerToggle()
            }) {
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
            // Используем medium impact для обоих типов (более приятный хаптик)
            .hapticFeedback(.impact(weight: .medium), trigger: togglePressed)
            
            // Manual entry button (only for Time habits)
            if habit.type == .time {
                Button(action: {
                    manualEntryPressed.toggle()
                    onManualEntry()
                }) {
                    Image(systemName: "plus.arrow.trianglehead.clockwise")
                        .font(.system(size: 24))
                        .tint(.primary)
                }
                .hapticFeedback(.impact(weight: .medium), trigger: manualEntryPressed)
            }
        }
        .padding(.bottom, 40)
    }
}
