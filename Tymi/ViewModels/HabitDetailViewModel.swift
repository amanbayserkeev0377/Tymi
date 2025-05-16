// The view model responsible for all habit detail operations including:
// - Progress tracking (counting, timing)
// - Persistence
// - Timer management
// - User input handling
//
// This component works with both current and past dates while maintaining
// data consistency between UI, services, and persistence layer.
//

import SwiftUI
import SwiftData

@Observable @MainActor
final class HabitDetailViewModel {
    // MARK: - Dependencies
    private let habit: Habit
    private let habitId: String
    private let date: Date
    var modelContext: ModelContext
    var habitsUpdateService: HabitsUpdateService
    var progressService: ProgressTrackingService
    
    // MARK: - State Properties
    private(set) var currentProgress: Int = 0
    private(set) var completionPercentage: Double = 0
    private(set) var formattedProgress: String = ""
    private(set) var isTimerRunning: Bool = false
    private var habitProgress: HabitProgress
    private var hasChanges = false
    private var cancellables: Task<Void, Never>? = nil
    
    // MARK: - UI State
    var isEditSheetPresented = false
    var alertState = AlertState()
    var onHabitDeleted: (() -> Void)?
    
    
    // MARK: - Constants
    private enum Limits {
        static let maxCount = 999999
        static let maxTimeSeconds = 86400 // 24 hours
    }
    
    // MARK: - Computed Properties
    var isAlreadyCompleted: Bool {
        currentProgress >= habit.goal
    }
    
    var formattedGoal: String {
        habit.formattedGoal
    }
    
    var isTodayView: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    // MARK: - Initialization
    init(
        habit: Habit,
        date: Date,
        modelContext: ModelContext,
        habitsUpdateService: HabitsUpdateService
    ) {
        self.habit = habit
        self.habitId = habit.uuid.uuidString
        self.date = date
        self.modelContext = modelContext
        self.habitsUpdateService = habitsUpdateService
        
        let initialProgress = habit.progressForDate(date)
        self.habitProgress = HabitProgress(
            habitId: habitId,
            date: date,
            value: initialProgress
        )
        self.currentProgress = initialProgress
        self.progressService = ProgressServiceProvider.getService(for: habit)
        updateProgressMetrics()
        
        let isToday = Calendar.current.isDateInToday(date)
        if !isToday && habit.type == .time {
            self.progressService = ProgressServiceProvider.getLocalService(
                for: habit,
                date: date,
                initialProgress: initialProgress,
                onUpdate: { [weak self] in
                    Task { @MainActor [weak self] in
                        self?.updateFromService()
                    }
                }
            )
        }
        
        if isToday && habit.type == .time {
            self.isTimerRunning = self.progressService.isTimerRunning(for: habitId)
            if self.isTimerRunning {
                let serviceProgress = self.progressService.getCurrentProgress(for: habitId)
                if serviceProgress > initialProgress {
                    self.currentProgress = serviceProgress
                    self.habitProgress.value = serviceProgress
                } else if initialProgress > 0 && serviceProgress == 0 {
                    self.progressService.addProgress(initialProgress, for: habitId)
                }
            } else if initialProgress > 0 {
                self.progressService.resetProgress(for: habitId)
                self.progressService.addProgress(initialProgress, for: habitId)
            }
        }
        
        setupObservers()
    }
    
    deinit {
    }
    
    // MARK: - Observer Setup
    private func setupObservers() {
        cancellables?.cancel()
        cancellables = Task { [weak self, date] in
            guard let self else { return }
            let observedDate = date
            
            while !Task.isCancelled {
                if self.date == observedDate && self.habit.type == .time && self.isTimerRunning {
                    let newProgress = self.progressService.getCurrentProgress(for: self.habitId)
                    if self.currentProgress != newProgress {
                        self.currentProgress = newProgress
                        self.habitProgress.value = newProgress
                        self.habitProgress.isDirty = true
                        self.updateProgressMetrics()
                        self.hasChanges = true
                    }
                    let isRunning = self.progressService.isTimerRunning(for: self.habitId)
                    if self.isTimerRunning != isRunning {
                        self.isTimerRunning = isRunning
                    }
                }
                do {
                    try await Task.sleep(for: .milliseconds(1000))
                } catch {
                    break
                }
            }
        }
    }
    
    // MARK: - Progress Management
    private func updateProgressMetrics() {
        completionPercentage = habit.goal > 0 ? Double(currentProgress) / Double(habit.goal) : 0
        formattedProgress = habit.type == .count ?
        currentProgress.formattedAsProgress(total: habit.goal) :
        currentProgress.formattedAsTime()
    }
    
    @MainActor
    private func updateFromService() {
        let newProgress = progressService.getCurrentProgress(for: habitId)
        if currentProgress != newProgress {
            currentProgress = newProgress
            habitProgress.value = newProgress
            habitProgress.isDirty = true
            updateProgressMetrics()
            hasChanges = true
        }
        let isRunning = progressService.isTimerRunning(for: habitId)
        if isTimerRunning != isRunning {
            isTimerRunning = isRunning
        }
    }
    
    
    
    // MARK: - Timer Management
    /// Toggles the timer state (start/stop) for time-based habits.
    /// For past dates, takes special care to preserve current progress value
    /// when starting the timer.
    func toggleTimer() {
        if isTimerRunning {
            isTimerRunning = false
            progressService.stopTimer(for: habitId)
            habitProgress.value = progressService.getCurrentProgress(for: habitId)
        } else {
            let currentValue = habitProgress.value
            if !isTodayView && habit.type == .time {
                progressService.resetProgress(for: habitId)
                if currentValue > 0 {
                    progressService.addProgress(currentValue, for: habitId)
                }
            }
            isTimerRunning = true
            progressService.startTimer(for: habitId, initialProgress: currentValue)
            let newProgress = progressService.getCurrentProgress(for: habitId)
            if newProgress < currentValue {
                progressService.stopTimer(for: habitId)
                progressService.resetProgress(for: habitId)
                progressService.addProgress(currentValue, for: habitId)
                isTimerRunning = true
                progressService.startTimer(for: habitId, initialProgress: currentValue)
            }
        }
        currentProgress = progressService.getCurrentProgress(for: habitId)
        habitProgress.value = currentProgress
        habitProgress.isDirty = true
        hasChanges = true
        saveProgress()
    }
    
    func addTimeValue(_ seconds: Int) {
        if isTimerRunning {
            isTimerRunning = false
            if isTodayView {
                progressService.stopTimer(for: habitId)
            }
        }
        habitProgress.value += seconds
        habitProgress.isDirty = true
        currentProgress = habitProgress.value
        if isTodayView {
            progressService.resetProgress(for: habitId)
            progressService.addProgress(currentProgress, for: habitId)
        }
        updateProgressMetrics()
        hasChanges = true
        saveProgress()
    }
    
    // MARK: - Habit Management
    func deleteHabit() {
        NotificationManager.shared.cancelNotifications(for: habit)
        modelContext.delete(habit)
        alertState.errorFeedbackTrigger.toggle()
        habitsUpdateService.triggerUpdate()
        onHabitDeleted?()
    }
    
    // MARK: - Progress Manipulation
    
    /// Increments the progress by 1 for count habits or by 1 minute (60 seconds) for time habits.
    /// For time habits, stops any running timer before incrementing.
    func incrementProgress() {
        if habit.type == .count {
            if habitProgress.value < Limits.maxCount {
                habitProgress.value += 1
                habitProgress.isDirty = true
                currentProgress = habitProgress.value
                if isTodayView {
                    progressService.resetProgress(for: habitId)
                    progressService.addProgress(currentProgress, for: habitId)
                }
                updateProgressMetrics()
                hasChanges = true
            } else {
                alertState.errorFeedbackTrigger.toggle()
            }
        } else {
            if isTimerRunning {
                progressService.stopTimer(for: habitId)
                isTimerRunning = false
            }
            if habitProgress.value + 60 <= Limits.maxTimeSeconds {
                habitProgress.value += 60
                habitProgress.isDirty = true
                currentProgress = habitProgress.value
                if isTodayView {
                    progressService.resetProgress(for: habitId)
                    progressService.addProgress(currentProgress, for: habitId)
                }
                updateProgressMetrics()
                hasChanges = true
            } else {
                habitProgress.value = Limits.maxTimeSeconds
                habitProgress.isDirty = true
                currentProgress = Limits.maxTimeSeconds
                if isTimerRunning {
                    progressService.stopTimer(for: habitId)
                    isTimerRunning = false
                }
                if isTodayView {
                    progressService.resetProgress(for: habitId)
                    progressService.addProgress(Limits.maxTimeSeconds, for: habitId)
                }
                updateProgressMetrics()
                hasChanges = true
                alertState.successFeedbackTrigger.toggle()
            }
        }
        saveProgress()
    }
    /// Decrements progress by 1 for count habits or by 1 minute (60 seconds) for time habits.
    /// For time habits, stops any running timer before decrementing.
    func decrementProgress() {
        if habit.type == .count {
            if habitProgress.value > 0 {
                habitProgress.value -= 1
                habitProgress.isDirty = true
                currentProgress = habitProgress.value
                if isTodayView {
                    progressService.resetProgress(for: habitId)
                    progressService.addProgress(currentProgress, for: habitId)
                }
                updateProgressMetrics()
                hasChanges = true
            }
        } else {
            if isTimerRunning {
                progressService.stopTimer(for: habitId)
                isTimerRunning = false
            }
            if habitProgress.value >= 60 {
                habitProgress.value -= 60
                habitProgress.isDirty = true
                currentProgress = habitProgress.value
                if isTodayView {
                    progressService.resetProgress(for: habitId)
                    progressService.addProgress(currentProgress, for: habitId)
                }
                updateProgressMetrics()
                hasChanges = true
            } else if habitProgress.value > 0 {
                habitProgress.value = 0
                habitProgress.isDirty = true
                currentProgress = 0
                if isTodayView {
                    progressService.resetProgress(for: habitId)
                }
                updateProgressMetrics()
                hasChanges = true
            }
        }
        saveProgress()
    }
    
    func resetProgress() {
        if isTimerRunning {
            progressService.stopTimer(for: habitId)
            isTimerRunning = false
        }
        progressService.resetProgress(for: habitId)
        habitProgress.value = 0
        habitProgress.isDirty = true
        currentProgress = 0
        updateProgressMetrics()
        hasChanges = true
        saveProgress()
        if !isTodayView {
            let serviceProgress = progressService.getCurrentProgress(for: habitId)
            if serviceProgress > 0 {
                progressService.resetProgress(for: habitId)
                saveProgress()
            }
        }
    }
    
    func completeHabit() {
        if currentProgress >= habit.goal {
            return
        }
        habitProgress.value = habit.goal
        habitProgress.isDirty = true
        currentProgress = habit.goal
        if isTodayView {
            progressService.resetProgress(for: habitId)
            progressService.addProgress(habit.goal, for: habitId)
        }
        updateProgressMetrics()
        hasChanges = true
        saveProgress()
        alertState.successFeedbackTrigger.toggle()
    }
    
    // MARK: - User Input Handling
    func handleCountInput() {
        guard let value = Int(alertState.countInputText), value > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            alertState.countInputText = ""
            return
        }
        if habitProgress.value + value > Limits.maxCount {
            let remainingValue = Limits.maxCount - habitProgress.value
            if remainingValue > 0 {
                habitProgress.value = Limits.maxCount
                habitProgress.isDirty = true
                currentProgress = Limits.maxCount
                progressService.resetProgress(for: habitId)
                progressService.addProgress(currentProgress, for: habitId)
                updateProgressMetrics()
                hasChanges = true
                alertState.successFeedbackTrigger.toggle()
            } else {
                alertState.errorFeedbackTrigger.toggle()
            }
        } else {
            habitProgress.value += value
            habitProgress.isDirty = true
            currentProgress = habitProgress.value
            progressService.resetProgress(for: habitId)
            progressService.addProgress(currentProgress, for: habitId)
            updateProgressMetrics()
            hasChanges = true
            alertState.successFeedbackTrigger.toggle()
        }
        saveProgress()
        alertState.countInputText = ""
    }
    
    func handleTimeInput() {
        let hours = Int(alertState.hoursInputText) ?? 0
        let minutes = Int(alertState.minutesInputText) ?? 0
        if hours == 0 && minutes == 0 {
            alertState.errorFeedbackTrigger.toggle()
            return
        }
        let secondsToAdd = hours * 3600 + minutes * 60
        if isTimerRunning {
            progressService.stopTimer(for: habitId)
            isTimerRunning = false
        }
        if habitProgress.value + secondsToAdd > Limits.maxTimeSeconds {
            let remainingSeconds = Limits.maxTimeSeconds - habitProgress.value
            if remainingSeconds > 0 {
                habitProgress.value = Limits.maxTimeSeconds
                habitProgress.isDirty = true
                currentProgress = Limits.maxTimeSeconds
                if isTodayView {
                    progressService.resetProgress(for: habitId)
                    progressService.addProgress(Limits.maxTimeSeconds, for: habitId)
                }
                updateProgressMetrics()
                hasChanges = true
                alertState.successFeedbackTrigger.toggle()
            } else {
                alertState.errorFeedbackTrigger.toggle()
            }
        } else {
            habitProgress.value += secondsToAdd
            habitProgress.isDirty = true
            currentProgress = habitProgress.value
            if isTodayView {
                progressService.resetProgress(for: habitId)
                progressService.addProgress(habitProgress.value, for: habitId)
            }
            updateProgressMetrics()
            hasChanges = true
            alertState.successFeedbackTrigger.toggle()
        }
        saveProgress()
        alertState.hoursInputText = ""
        alertState.minutesInputText = ""
    }
    
    // MARK: - Persistence
    /// Saves the current progress to the database if there are any pending changes.
    /// Updates the habit completions by replacing any existing entries for the same date.
    func saveProgress() {
        if habitProgress.isDirty {
            do {
                let uuid = habit.uuid
                let descriptor = FetchDescriptor<Habit>(predicate: #Predicate<Habit> { h in
                    h.uuid == uuid
                })
                let habits = try modelContext.fetch(descriptor)
                guard let habit = habits.first else {
                    return
                }
                let targetDate = habitProgress.date
                let oldCompletions = habit.completions.filter {
                    Calendar.current.isDate($0.date, inSameDayAs: targetDate)
                }
                for completion in oldCompletions {
                    modelContext.delete(completion)
                }
                if habitProgress.value > 0 {
                    let newCompletion = HabitCompletion(
                        date: targetDate,
                        value: habitProgress.value,
                        habit: habit
                    )
                    habit.completions.append(newCompletion)
                }
                try modelContext.save()
                habitProgress.isDirty = false
                hasChanges = false
                Task {
                    await habitsUpdateService.triggerDelayedUpdate(delay: 0.3)
                }
            } catch {
                print("Failed to save progress: \(error)")
            }
        }
    }
    
    func saveIfNeeded() {
        if hasChanges || habitProgress.isDirty {
            saveProgress()
        }
    }
    
    func cleanup(stopTimer: Bool = true) {
        cancellables?.cancel()
        cancellables = nil
        if hasChanges || habitProgress.isDirty {
            saveProgress()
        }
        onHabitDeleted = nil
        if stopTimer && isTimerRunning {
            progressService.stopTimer(for: habitId)
        }
    }
}
