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
        HStack(spacing: 18) {
            // 1. Reset
            Button {
                resetPressed.toggle()
                onReset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 24))
                    .foregroundStyle(.primary)
                    .frame(minWidth: 44, minHeight: 44)
                    .rotateResetAnimation(isActive: resetPressed)
            }
            .errorHaptic(trigger: resetPressed)
            .accessibilityLabel("Reset")
            
            if habit.type == .time {
                // 2. Play/Pause
                Button {
                    togglePressed.toggle()
                    onTimerToggle()
                } label: {
                    Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 42))
                        .contentTransition(.symbolEffect(.replace, options: .speed(2.5)))
                        .foregroundStyle(.primary)
                        .frame(minWidth: 52, minHeight: 52)
                }
                .hapticFeedback(.impact(weight: .medium), trigger: togglePressed)
                .accessibilityLabel(isTimerRunning ? "Pause" : "Play")
            }
            
            // 3. Manual Entry
            Button {
                manualEntryPressed.toggle()
                onManualEntry()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                    .foregroundStyle(.primary)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .hapticFeedback(.impact(weight: .medium), trigger: manualEntryPressed)
            .accessibilityLabel("Manual Entry")
        }
        .frame(maxWidth: 300)
        .frame(maxWidth: .infinity)
        .frame(height: 80)
    }
}

// MARK: - iOS Version Specific Modifiers

extension View {
    @ViewBuilder
    func rotateResetAnimation(isActive: Bool) -> some View {
        if #available(iOS 18.0, *) {
            self.symbolEffect(.rotate, options: .speed(4.5), value: isActive)
        } else {
            self.symbolEffect(.bounce.byLayer, options: .speed(2), value: isActive)
        }
    }
}
