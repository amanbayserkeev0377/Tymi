import SwiftUI

// MARK: - Common AlertState
struct AlertState: Equatable {
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
    
    static func == (lhs: AlertState, rhs: AlertState) -> Bool {
        return lhs.isResetAlertPresented == rhs.isResetAlertPresented &&
               lhs.isCountAlertPresented == rhs.isCountAlertPresented &&
               lhs.isTimeAlertPresented == rhs.isTimeAlertPresented &&
               lhs.isDeleteAlertPresented == rhs.isDeleteAlertPresented &&
               lhs.isFreezeAlertPresented == rhs.isFreezeAlertPresented &&
               lhs.countInputText == rhs.countInputText &&
               lhs.hoursInputText == rhs.hoursInputText &&
               lhs.minutesInputText == rhs.minutesInputText &&
               lhs.successFeedbackTrigger == rhs.successFeedbackTrigger &&
               lhs.errorFeedbackTrigger == rhs.errorFeedbackTrigger
    }
}

// MARK: - Alert Modifiers

// Reset Progress Alert
struct ResetProgressAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onReset: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("reset_progress_confirmation".localized, isPresented: $isPresented) {
                Button("cancel".localized, role: .cancel) { }
                Button("reset".localized, role: .destructive) {
                    onReset()
                }
            }
    }
}

// Count Input Alert
struct CountInputAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var inputText: String
    let timerService: HabitTimerService
    let habitId: String
    @Binding var successTrigger: Bool
    @Binding var errorTrigger: Bool
    
    func body(content: Content) -> some View {
        content
            .alert("add_count".localized, isPresented: $isPresented) {
                TextField("count".localized, text: $inputText)
                    .keyboardType(.numberPad)
                Button("cancel".localized, role: .cancel) { }
                Button("add".localized) {
                    if let count = Int(inputText) {
                        timerService.addProgress(count, for: habitId)
                        successTrigger.toggle()
                    } else {
                        errorTrigger.toggle()
                    }
                    inputText = ""
                }
            } message: {
                Text("enter_completion_count".localized)
            }
    }
}

// Time Input Alert
struct TimeInputAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var hoursText: String
    @Binding var minutesText: String
    let timerService: HabitTimerService
    let habitId: String
    @Binding var successTrigger: Bool
    @Binding var errorTrigger: Bool
    
    func body(content: Content) -> some View {
        content
            .alert("add_time".localized, isPresented: $isPresented) {
                TextField("hours_less_than_24".localized, text: $hoursText)
                    .keyboardType(.numberPad)
                TextField("minutes_less_than_60".localized, text: $minutesText)
                    .keyboardType(.numberPad)
                Button("cancel".localized, role: .cancel) { }
                Button("add".localized) {
                    let hours = Int(hoursText) ?? 0
                    let minutes = Int(minutesText) ?? 0
                    let totalSeconds = hours * 3600 + minutes * 60
                    
                    // Проверяем валидность ввода
                    let isValidInput = (hours > 0 || minutes > 0) && hours < 25 && minutes < 60
                    
                    if isValidInput && totalSeconds > 0 {
                        // Вызываем метод обработки
                        if timerService.isTimerRunning(for: habitId) {
                            timerService.stopTimer(for: habitId)
                        }
                        
                        // Получаем текущий прогресс и проверяем лимит 24 часов
                        let currentProgress = timerService.getCurrentProgress(for: habitId)
                        if currentProgress + totalSeconds > 86400 {
                            let remainingSeconds = 86400 - currentProgress
                            if remainingSeconds > 0 {
                                timerService.addProgress(remainingSeconds, for: habitId)
                            }
                        } else {
                            timerService.addProgress(totalSeconds, for: habitId)
                        }
                        
                        successTrigger.toggle()
                    } else {
                        errorTrigger.toggle()
                    }
                    
                    hoursText = ""
                    minutesText = ""
                }
            } message: {
                Text("enter_time_spent".localized)
            }
    }
}

// Delete Habit Alert
struct DeleteHabitAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onDelete: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("delete_habit_confirmation".localized, isPresented: $isPresented) {
                Button("cancel".localized, role: .cancel) { }
                Button("delete".localized, role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("freeze_instead_message".localized)
            }
    }
}

// Freeze Habit Alert
struct FreezeHabitAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onDismiss: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("frozen_habit_info".localized, isPresented: $isPresented) {
                Button("okay".localized, action: onDismiss)
            }
            .tint(.primary)
    }
}

// MARK: - View Extensions

extension View {
    func resetProgressAlert(isPresented: Binding<Bool>, onReset: @escaping () -> Void) -> some View {
        self.modifier(ResetProgressAlertModifier(isPresented: isPresented, onReset: onReset))
    }
    
    func countInputAlert(
        isPresented: Binding<Bool>,
        inputText: Binding<String>,
        timerService: HabitTimerService,
        habitId: String,
        successTrigger: Binding<Bool>,
        errorTrigger: Binding<Bool>
    ) -> some View {
        self.modifier(CountInputAlertModifier(
            isPresented: isPresented,
            inputText: inputText,
            timerService: timerService,
            habitId: habitId,
            successTrigger: successTrigger,
            errorTrigger: errorTrigger
        ))
    }
    
    func timeInputAlert(
        isPresented: Binding<Bool>,
        hoursText: Binding<String>,
        minutesText: Binding<String>,
        timerService: HabitTimerService,
        habitId: String,
        successTrigger: Binding<Bool>,
        errorTrigger: Binding<Bool>
    ) -> some View {
        self.modifier(TimeInputAlertModifier(
            isPresented: isPresented,
            hoursText: hoursText,
            minutesText: minutesText,
            timerService: timerService,
            habitId: habitId,
            successTrigger: successTrigger,
            errorTrigger: errorTrigger
        ))
    }
    
    func deleteHabitAlert(isPresented: Binding<Bool>, onDelete: @escaping () -> Void) -> some View {
        self.modifier(DeleteHabitAlertModifier(isPresented: isPresented, onDelete: onDelete))
    }
    
    func freezeHabitAlert(isPresented: Binding<Bool>, onDismiss: @escaping () -> Void) -> some View {
        self.modifier(FreezeHabitAlertModifier(isPresented: isPresented, onDismiss: onDismiss))
    }
    
    // Упрощенный комбинированный модификатор для HabitDetailView
    func habitAlerts(
        alertState: Binding<AlertState>,
        habit: Habit,
        timerService: HabitTimerService,
        onReset: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        self
            .resetProgressAlert(isPresented: alertState.isResetAlertPresented, onReset: onReset)
            .deleteHabitAlert(isPresented: alertState.isDeleteAlertPresented, onDelete: onDelete)
            .countInputAlert(
                isPresented: alertState.isCountAlertPresented,
                inputText: alertState.countInputText,
                timerService: timerService,
                habitId: habit.id,
                successTrigger: alertState.successFeedbackTrigger,
                errorTrigger: alertState.errorFeedbackTrigger
            )
            .timeInputAlert(
                isPresented: alertState.isTimeAlertPresented,
                hoursText: alertState.hoursInputText,
                minutesText: alertState.minutesInputText,
                timerService: timerService,
                habitId: habit.id,
                successTrigger: alertState.successFeedbackTrigger,
                errorTrigger: alertState.errorFeedbackTrigger
            )
    }
}
