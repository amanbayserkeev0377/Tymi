import SwiftUI

// MARK: - Common AlertState
struct AlertState: Equatable {
    var isCountAlertPresented: Bool = false
    var isTimeAlertPresented: Bool = false
    var isDeleteAlertPresented: Bool = false
    var date: Date? = nil
    
    var countInputText: String = ""
    var hoursInputText: String = ""
    var minutesInputText: String = ""
    
    var successFeedbackTrigger: Bool = false
    var errorFeedbackTrigger: Bool = false
    
    static func == (lhs: AlertState, rhs: AlertState) -> Bool {
        return lhs.isCountAlertPresented == rhs.isCountAlertPresented &&
        lhs.isTimeAlertPresented == rhs.isTimeAlertPresented &&
        lhs.isDeleteAlertPresented == rhs.isDeleteAlertPresented &&
        lhs.countInputText == rhs.countInputText &&
        lhs.hoursInputText == rhs.hoursInputText &&
        lhs.minutesInputText == rhs.minutesInputText &&
        lhs.date?.timeIntervalSince1970 == rhs.date?.timeIntervalSince1970
    }
}

// MARK: - Alert Modifiers

// Count Input Alert
struct CountInputAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var inputText: String
    let progressService: ProgressTrackingService
    let habitId: String
    @Binding var successTrigger: Bool
    @Binding var errorTrigger: Bool
    let onCountInput: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("alert_add_count".localized, isPresented: $isPresented) {
                TextField("count".localized, text: $inputText)
                    .keyboardType(.numberPad)
                Button("button_cancel".localized, role: .cancel) { }
                Button("button_add".localized) {
                    if let count = Int(inputText) {
                        progressService.addProgress(count, for: habitId)
                        onCountInput()
                        successTrigger.toggle()
                    } else {
                        errorTrigger.toggle()
                    }
                    inputText = ""
                }
            } message: {
                Text("alert_add_count_message".localized)
            }
    }
}

// Time Input Alert
struct TimeInputAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var hoursText: String
    @Binding var minutesText: String
    let progressService: ProgressTrackingService
    let habitId: String
    @Binding var successTrigger: Bool
    @Binding var errorTrigger: Bool
    let onTimeInput: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("alert_add_time".localized, isPresented: $isPresented) {
                TextField("hours_less_than_24".localized, text: $hoursText)
                    .keyboardType(.numberPad)
                TextField("minutes_less_than_60".localized, text: $minutesText)
                    .keyboardType(.numberPad)
                Button("button_cancel".localized, role: .cancel) { }
                Button("button_add".localized) {
                    onTimeInput()
                }
            } message: {
                Text("alert_add_time_message".localized)
            }
    }
}

// MARK: - Unified Delete Alerts

// Single Habit Delete Alert
struct DeleteSingleHabitAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let habitName: String
    let onDelete: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("alert_delete_habit".localized, isPresented: $isPresented) {
                Button("button_cancel".localized, role: .cancel) { }
                Button("button_delete".localized, role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("alert_delete_habit_message".localized(with: habitName))
            }
    }
}

// Multiple Habits Delete Alert
struct DeleteMultipleHabitsAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let habitsCount: Int
    let onDelete: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("alert_delete_multiple_habits".localized, isPresented: $isPresented) {
                Button("button_cancel".localized, role: .cancel) { }
                Button("button_delete".localized, role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("alert_delete_multiple_habits_message".localized(with: habitsCount))
            }
    }
}

// MARK: - Folder Delete Alerts

// Single Folder Delete Alert
struct DeleteSingleFolderAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let folderName: String
    let onDelete: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("alert_delete_folder".localized, isPresented: $isPresented) {
                Button("button_cancel".localized, role: .cancel) { }
                Button("button_delete".localized, role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("alert_delete_folder_message".localized(with: folderName))
            }
    }
}

// Multiple Folders Delete Alert
struct DeleteMultipleFoldersAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let foldersCount: Int
    let onDelete: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("alert_delete_folders".localized, isPresented: $isPresented) {
                Button("button_cancel".localized, role: .cancel) { }
                Button("button_delete".localized, role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("alert_delete_folders_message".localized(with: foldersCount))
            }
    }
}

// MARK: - View Extensions

extension View {
    
    func countInputAlert(
        isPresented: Binding<Bool>,
        inputText: Binding<String>,
        progressService: ProgressTrackingService,
        habitId: String,
        successTrigger: Binding<Bool>,
        errorTrigger: Binding<Bool>,
        onCountInput: @escaping () -> Void
    ) -> some View {
        self.modifier(CountInputAlertModifier(
            isPresented: isPresented,
            inputText: inputText,
            progressService: progressService,
            habitId: habitId,
            successTrigger: successTrigger,
            errorTrigger: errorTrigger,
            onCountInput: onCountInput
        ))
    }
    
    func timeInputAlert(
        isPresented: Binding<Bool>,
        hoursText: Binding<String>,
        minutesText: Binding<String>,
        progressService: ProgressTrackingService,
        habitId: String,
        successTrigger: Binding<Bool>,
        errorTrigger: Binding<Bool>,
        onTimeInput: @escaping () -> Void
    ) -> some View {
        self.modifier(TimeInputAlertModifier(
            isPresented: isPresented,
            hoursText: hoursText,
            minutesText: minutesText,
            progressService: progressService,
            habitId: habitId,
            successTrigger: successTrigger,
            errorTrigger: errorTrigger,
            onTimeInput: onTimeInput
        ))
    }
    
    // MARK: - Unified Delete Alert Extensions
    
    /// Alert for deleting a single habit
    func deleteSingleHabitAlert(
        isPresented: Binding<Bool>,
        habitName: String,
        onDelete: @escaping () -> Void
    ) -> some View {
        self.modifier(DeleteSingleHabitAlertModifier(
            isPresented: isPresented,
            habitName: habitName,
            onDelete: onDelete
        ))
    }
    
    /// Alert for deleting multiple habits
    func deleteMultipleHabitsAlert(
        isPresented: Binding<Bool>,
        habitsCount: Int,
        onDelete: @escaping () -> Void
    ) -> some View {
        self.modifier(DeleteMultipleHabitsAlertModifier(
            isPresented: isPresented,
            habitsCount: habitsCount,
            onDelete: onDelete
        ))
    }
    
    // MARK: - Folder Delete Alert Extensions

    /// Alert for deleting a single folder
    func deleteSingleFolderAlert(
        isPresented: Binding<Bool>,
        folderName: String,
        onDelete: @escaping () -> Void
    ) -> some View {
        self.modifier(DeleteSingleFolderAlertModifier(
            isPresented: isPresented,
            folderName: folderName,
            onDelete: onDelete
        ))
    }

    /// Alert for deleting multiple folders
    func deleteMultipleFoldersAlert(
        isPresented: Binding<Bool>,
        foldersCount: Int,
        onDelete: @escaping () -> Void
    ) -> some View {
        self.modifier(DeleteMultipleFoldersAlertModifier(
            isPresented: isPresented,
            foldersCount: foldersCount,
            onDelete: onDelete
        ))
    }
    
    // MARK: - Legacy Combined Modifier for HabitDetailView
    
    /// Combined alerts for HabitDetailView (backward compatibility)
    func habitAlerts(
        alertState: Binding<AlertState>,
        habit: Habit,
        progressService: ProgressTrackingService,
        onDelete: @escaping () -> Void,
        onCountInput: @escaping () -> Void,
        onTimeInput: @escaping () -> Void
    ) -> some View {
        self
            .deleteSingleHabitAlert(
                isPresented: alertState.isDeleteAlertPresented,
                habitName: habit.title,
                onDelete: onDelete
            )
            .countInputAlert(
                isPresented: alertState.isCountAlertPresented,
                inputText: alertState.countInputText,
                progressService: progressService,
                habitId: habit.uuid.uuidString,
                successTrigger: alertState.successFeedbackTrigger,
                errorTrigger: alertState.errorFeedbackTrigger,
                onCountInput: onCountInput
            )
            .timeInputAlert(
                isPresented: alertState.isTimeAlertPresented,
                hoursText: alertState.hoursInputText,
                minutesText: alertState.minutesInputText,
                progressService: progressService,
                habitId: habit.uuid.uuidString,
                successTrigger: alertState.successFeedbackTrigger,
                errorTrigger: alertState.errorFeedbackTrigger,
                onTimeInput: onTimeInput
            )
    }
}
