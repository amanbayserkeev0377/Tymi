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
            .alert("reset_progress_confirmation".localized, isPresented: $isResetAlertPresented) {
                Button("Cancel".localized, role: .cancel) { }
                Button("reset".localized, role: .destructive) {
                    onReset()
                }
            }
            
            .alert("Add Count".localized, isPresented: $isCountAlertPresented) {
                TextField("Count".localized, text: $countInputText)
                    .keyboardType(.numberPad)
                Button("Cancel".localized, role: .cancel) { }
                Button("Add".localized) {
                    if let count = Int(countInputText) {
                        timerService.addProgress(count, for: habit.id)
                        successFeedbackTrigger.toggle()
                    } else {
                        errorFeedbackTrigger.toggle()
                    }
                    countInputText = ""
                }
            } message: {
                Text("Enter the number of times you completed this habit".localized)
            }
            
            .alert("Add Time".localized, isPresented: $isTimeAlertPresented) {
                TextField("Hours".localized, text: $hoursInputText)
                    .keyboardType(.numberPad)
                TextField("Minutes".localized, text: $minutesInputText)
                    .keyboardType(.numberPad)
                Button("Cancel".localized, role: .cancel) { }
                Button("Add".localized) {
                    let hours = Int(hoursInputText) ?? 0
                    let minutes = Int(minutesInputText) ?? 0
                    let totalSeconds = hours * 3600 + minutes * 60
                    if totalSeconds > 0 {
                        timerService.addProgress(totalSeconds, for: habit.id)
                        successFeedbackTrigger.toggle()
                    } else {
                        errorFeedbackTrigger.toggle()
                    }
                    hoursInputText = ""
                    minutesInputText = ""
                }
            } message: {
                Text("Enter the time you spent on this habit".localized)
            }
            
            .deleteHabitAlert(isPresented: $isDeleteAlertPresented) {
                onDelete()
            }
    }
}

extension View {
    func habitDetailAlerts(
        habit: Habit,
        date: Date,
        timerService: HabitTimerService,
        isResetAlertPresented: Binding<Bool>,
        isCountAlertPresented: Binding<Bool>,
        isTimeAlertPresented: Binding<Bool>,
        isDeleteAlertPresented: Binding<Bool>,
        countInputText: Binding<String>,
        hoursInputText: Binding<String>,
        minutesInputText: Binding<String>,
        successFeedbackTrigger: Binding<Bool>,
        errorFeedbackTrigger: Binding<Bool>,
        onReset: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        modifier(HabitDetailAlerts(
            habit: habit,
            date: date,
            timerService: timerService,
            isResetAlertPresented: isResetAlertPresented,
            isCountAlertPresented: isCountAlertPresented,
            isTimeAlertPresented: isTimeAlertPresented,
            isDeleteAlertPresented: isDeleteAlertPresented,
            countInputText: countInputText,
            hoursInputText: hoursInputText,
            minutesInputText: minutesInputText,
            successFeedbackTrigger: successFeedbackTrigger,
            errorFeedbackTrigger: errorFeedbackTrigger,
            onReset: onReset,
            onDelete: onDelete
        ))
    }
}
