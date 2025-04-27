import SwiftUI

struct HabitDetailAlerts: ViewModifier {
    let habit: Habit
    let date: Date
    let timerService: HabitTimerService
    
    @Binding var isResetAlertPresented: Bool
    @Binding var isCountAlertPresented: Bool
    @Binding var isTimeAlertPresented: Bool
    @Binding var isDeleteAlertPresented: Bool
    
    @Binding var countInputText: String
    @Binding var hoursInputText: String
    @Binding var minutesInputText: String
    
    @Binding var successFeedbackTrigger: Bool
    @Binding var errorFeedbackTrigger: Bool
    
    let onReset: () -> Void
    let onDelete: () -> Void
    
    func body(content: Content) -> some View {
        content
            // Reset confirmation alert
            .alert("Reset Progress", isPresented: $isResetAlertPresented) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    errorFeedbackTrigger.toggle()
                    onReset()
                }
            } message: {
                Text("Do you want to reset your progress for today?")
            }
            
            // Delete confirmation alert
            .alert("Confirmation", isPresented: $isDeleteAlertPresented) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("Do you want to delete this habit?")
            }
            
            // Alert for Count type
            .alert("Enter count", isPresented: $isCountAlertPresented) {
                TextField("", text: $countInputText)
                    .keyboardType(.numberPad)
                Button("Cancel", role: .cancel) {
                    countInputText = ""
                }
                Button("Add") {
                    if let value = Int(countInputText), value > 0 {
                        timerService.addProgress(value, for: habit.id)
                        successFeedbackTrigger.toggle()
                    }
                    countInputText = ""
                }
            }
            .tint(.primary)
            
            // Alert for Time type
            .alert("Enter time", isPresented: $isTimeAlertPresented) {
                TextField("hours", text: $hoursInputText)
                    .keyboardType(.numberPad)
                TextField("minutes", text: $minutesInputText)
                    .keyboardType(.numberPad)
                Button("Cancel", role: .cancel) {
                    hoursInputText = ""
                    minutesInputText = ""
                }
                Button("Add") {
                    let minutes = Int(minutesInputText) ?? 0
                    let hours = Int(hoursInputText) ?? 0
                    
                    // Convert to seconds and add to progress
                    let totalSeconds = (hours * 3600) + (minutes * 60)
                    if totalSeconds > 0 {
                        timerService.addProgress(totalSeconds, for: habit.id)
                        successFeedbackTrigger.toggle()
                    }
                    
                    // Clear input fields
                    minutesInputText = ""
                    hoursInputText = ""
                }
            }
            .tint(.primary)
    }
} 
