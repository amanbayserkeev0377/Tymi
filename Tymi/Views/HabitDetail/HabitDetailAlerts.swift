import SwiftUI

struct AlertState {
    var isResetAlertPresented: Bool = false
    var isCountAlertPresented: Bool = false
    var isTimeAlertPresented: Bool = false
    var isDeleteAlertPresented: Bool = false
    var isFreezeAlertPresented: Bool = false
    
    var countInputText: String = ""
    var hoursInputText: String = ""
    var minutesInputText: String = ""
    
    var successFeedbackTrigger: Bool = false
    var errorFeedbackTrigger: Bool = false
}

struct HabitDetailAlerts: ViewModifier {
    let habit: Habit
    let date: Date
    let timerService: HabitTimerService
    
    @Binding var alertState: AlertState
    
    let onReset: () -> Void
    let onDelete: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("reset_progress_confirmation".localized, isPresented: $alertState.isResetAlertPresented) {
                Button("cancel".localized, role: .cancel) { }
                Button("reset".localized, role: .destructive) {
                    onReset()
                }
            }
            
            .alert("add_count".localized, isPresented: $alertState.isCountAlertPresented) {
                TextField("count".localized, text: $alertState.countInputText)
                    .keyboardType(.numberPad)
                Button("cancel".localized, role: .cancel) { }
                Button("add".localized) {
                    if let count = Int(alertState.countInputText) {
                        timerService.addProgress(count, for: habit.id)
                        alertState.successFeedbackTrigger.toggle()
                    } else {
                        alertState.errorFeedbackTrigger.toggle()
                    }
                    alertState.countInputText = ""
                }
            } message: {
                Text("enter_completion_count".localized)
            }
            
            .alert("add_time".localized, isPresented: $alertState.isTimeAlertPresented) {
                TextField("hours_less_than_24".localized, text: $alertState.hoursInputText)
                    .keyboardType(.numberPad)
                TextField("minutes_less_than_60".localized, text: $alertState.minutesInputText)
                    .keyboardType(.numberPad)
                Button("cancel".localized, role: .cancel) { }
                Button("add".localized) {
                    let hours = Int(alertState.hoursInputText) ?? 0
                    let minutes = Int(alertState.minutesInputText) ?? 0
                    let totalSeconds = hours * 3600 + minutes * 60
                    
                    // Проверяем валидность ввода
                    let isValidInput = (hours > 0 || minutes > 0) && hours < 25 && minutes < 60
                    
                    if isValidInput && totalSeconds > 0 {
                        // Вызываем метод обработки в ViewModel
                        if timerService.isTimerRunning(for: habit.id) {
                            timerService.stopTimer(for: habit.id)
                        }
                        
                        // Получаем текущий прогресс и проверяем лимит 24 часов
                        let currentProgress = timerService.getCurrentProgress(for: habit.id)
                        if currentProgress + totalSeconds > 86400 {
                            let remainingSeconds = 86400 - currentProgress
                            if remainingSeconds > 0 {
                                timerService.addProgress(remainingSeconds, for: habit.id)
                            }
                        } else {
                            timerService.addProgress(totalSeconds, for: habit.id)
                        }
                        
                        alertState.successFeedbackTrigger.toggle()
                    } else {
                        alertState.errorFeedbackTrigger.toggle()
                    }
                    
                    alertState.hoursInputText = ""
                    alertState.minutesInputText = ""
                }
            } message: {
                Text("enter_time_spent".localized)
            }
    }
}

extension View {
    func habitDetailAlerts(
        habit: Habit,
        date: Date,
        timerService: HabitTimerService,
        alertState: Binding<AlertState>,
        onReset: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        modifier(HabitDetailAlerts(
            habit: habit,
            date: date,
            timerService: timerService,
            alertState: alertState,
            onReset: onReset,
            onDelete: onDelete
        ))
    }
}
