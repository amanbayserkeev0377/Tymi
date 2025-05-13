import SwiftUI

// MARK: - Common AlertState
struct AlertState: Equatable {
    var isResetAlertPresented: Bool = false
    var isCountAlertPresented: Bool = false
    var isTimeAlertPresented: Bool = false
    var isDeleteAlertPresented: Bool = false
    
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
        lhs.countInputText == rhs.countInputText &&
        lhs.hoursInputText == rhs.hoursInputText &&
        lhs.minutesInputText == rhs.minutesInputText
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
    let progressService: ProgressTrackingService  // Изменено с timerService
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
                        progressService.addProgress(count, for: habitId)  // Используем progressService
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
    let progressService: ProgressTrackingService  // Изменено с timerService
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
                        if progressService.isTimerRunning(for: habitId) {  // Используем progressService
                            progressService.stopTimer(for: habitId)  // Используем progressService
                        }
                        
                        // Получаем текущий прогресс и проверяем лимит 24 часов
                        let currentProgress = progressService.getCurrentProgress(for: habitId)  // Используем progressService
                        if currentProgress + totalSeconds > 86400 {
                            let remainingSeconds = 86400 - currentProgress
                            if remainingSeconds > 0 {
                                progressService.addProgress(remainingSeconds, for: habitId)  // Используем progressService
                            }
                        } else {
                            progressService.addProgress(totalSeconds, for: habitId)  // Используем progressService
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
                Text("delete_message".localized)
            }
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
        progressService: ProgressTrackingService,  // Изменено с timerService
        habitId: String,
        successTrigger: Binding<Bool>,
        errorTrigger: Binding<Bool>
    ) -> some View {
        self.modifier(CountInputAlertModifier(
            isPresented: isPresented,
            inputText: inputText,
            progressService: progressService,  // Изменено с timerService
            habitId: habitId,
            successTrigger: successTrigger,
            errorTrigger: errorTrigger
        ))
    }
    
    func timeInputAlert(
        isPresented: Binding<Bool>,
        hoursText: Binding<String>,
        minutesText: Binding<String>,
        progressService: ProgressTrackingService,  // Изменено с timerService
        habitId: String,
        successTrigger: Binding<Bool>,
        errorTrigger: Binding<Bool>
    ) -> some View {
        self.modifier(TimeInputAlertModifier(
            isPresented: isPresented,
            hoursText: hoursText,
            minutesText: minutesText,
            progressService: progressService,  // Изменено с timerService
            habitId: habitId,
            successTrigger: successTrigger,
            errorTrigger: errorTrigger
        ))
    }
    
    func deleteHabitAlert(isPresented: Binding<Bool>, onDelete: @escaping () -> Void) -> some View {
        self.modifier(DeleteHabitAlertModifier(isPresented: isPresented, onDelete: onDelete))
    }
    
    
    // Упрощенный комбинированный модификатор для HabitDetailView
    func habitAlerts(
        alertState: Binding<AlertState>,
        habit: Habit,
        progressService: ProgressTrackingService,  // Изменено с timerService
        onReset: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        self
            .resetProgressAlert(isPresented: alertState.isResetAlertPresented, onReset: onReset)
            .deleteHabitAlert(isPresented: alertState.isDeleteAlertPresented, onDelete: onDelete)
            .countInputAlert(
                isPresented: alertState.isCountAlertPresented,
                inputText: alertState.countInputText,
                progressService: progressService,  // Изменено с timerService
                habitId: habit.uuid.uuidString,
                successTrigger: alertState.successFeedbackTrigger,
                errorTrigger: alertState.errorFeedbackTrigger
            )
            .timeInputAlert(
                isPresented: alertState.isTimeAlertPresented,
                hoursText: alertState.hoursInputText,
                minutesText: alertState.minutesInputText,
                progressService: progressService,  // Изменено с timerService
                habitId: habit.uuid.uuidString,
                successTrigger: alertState.successFeedbackTrigger,
                errorTrigger: alertState.errorFeedbackTrigger
            )
    }
}
