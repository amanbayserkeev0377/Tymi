import SwiftUI
import SwiftData

@Observable
@MainActor
final class HabitDetailViewModel {
    // MARK: - Dependencies
    private let habit: Habit
    private let habitId: String
    private let date: Date
    var modelContext: ModelContext
    var habitsUpdateService: HabitsUpdateService
    var timerService: HabitTimerService
    private let statsManager: StatsManager
    
    // MARK: - State Properties
    private(set) var currentProgress: Int = 0
    private(set) var completionPercentage: Double = 0
    private(set) var formattedProgress: String = ""
    private(set) var isTimerRunning: Bool = false
    
    // MARK: - Statistics Properties
    private(set) var currentStreak: Int = 0
    private(set) var bestStreak: Int = 0
    private(set) var totalCompletions: Int = 0
    
    // MARK: - UI State
    var isEditSheetPresented = false
    var alertState = AlertState()
    
    
    // Need filter
    private var hasChanges = false
    private var saveDebounceTask: Task<Void, Never>?
    var onHabitDeleted: (() -> Void)?
    
    private var progressObserverTask: Task<Void, Never>?
    private var timerStateObserverTask: Task<Void, Never>?
    
    private enum Limits {
        static let maxCount = 999999
        static let maxTimeSeconds = 86400 // 24hr
    }
    
    // MARK: - Computed Properties
    var isAlreadyCompleted: Bool {
        currentProgress >= habit.goal
    }
    
    var formattedGoal: String {
        habit.formattedGoal
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
        self.timerService = .shared
        self.statsManager = StatsManager(modelContext: modelContext)
        
        setupInitialState()
        setupObservers()
        updateStatistics()
    }
    
    // MARK: - Setup
    private func setupInitialState() {
        currentProgress = timerService.getCurrentProgress(for: habitId)
        updateProgressMetrics()
        
        if habit.type == .time {
            isTimerRunning = timerService.isTimerRunning(for: habitId)
        }
    }
    
    private func setupObservers() {
        // Сначала отменяем предыдущие задачи, если они существуют
        progressObserverTask?.cancel()
        timerStateObserverTask?.cancel()
            
        // Запускаем наблюдение за прогрессом
        progressObserverTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            for await updates in self.timerService.progressUpdatesSequence {
                // Проверяем, не была ли задача отменена
                if Task.isCancelled { break }
                
                if let progress = updates[self.habitId] {
                    if !Task.isCancelled {
                        await MainActor.run {
                            self.currentProgress = progress
                            self.updateProgressMetrics()
                            self.hasChanges = true
                        }
                    }
                }
            }
        }
        
        // Запускаем наблюдение за состоянием таймера
        timerStateObserverTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            for await _ in self.timerService.objectWillChangeSequence {
                // Проверяем, не была ли задача отменена
                if Task.isCancelled { break }
                
                await MainActor.run {
                    self.isTimerRunning = self.timerService.isTimerRunning(for: self.habitId)
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
    
    func incrementProgress() {
        if habit.type == .count {
            let currentValue = timerService.getCurrentProgress(for: habitId)
            if currentValue < Limits.maxCount {
                timerService.addProgress(1, for: habitId)
            } else {
                alertState.errorFeedbackTrigger.toggle()
            }
        } else {
            let currentValue = timerService.getCurrentProgress(for: habitId)
            if currentValue + 60 <= Limits.maxTimeSeconds {
                if timerService.isTimerRunning(for: habitId) {
                    timerService.stopTimer(for: habitId)
                }
                timerService.addProgress(60, for: habitId)
            } else {
                timerService.resetTimer(for: habitId)
                timerService.addProgress(Limits.maxTimeSeconds, for: habitId)
                
                alertState.successFeedbackTrigger.toggle()
            }
        }
        updateProgress()
    }
    
    func decrementProgress() {
        if habit.type == .count {
            let currentValue = timerService.getCurrentProgress(for: habitId)
            if currentValue > 0 {
                timerService.addProgress(-1, for: habitId)
            }
        } else {
            if timerService.isTimerRunning(for: habitId) {
                timerService.stopTimer(for: habitId)
            }
            
            let currentValue = timerService.getCurrentProgress(for: habitId)
            if currentValue >= 60 {
                timerService.addProgress(-60, for: habitId)
            } else if currentValue > 0 {
                timerService.resetTimer(for: habitId)
            }
        }
        updateProgress()
    }
    
    private func updateProgress() {
        currentProgress = timerService.getCurrentProgress(for: habitId)
        updateProgressMetrics()
        hasChanges = true
        
        saveDebounceTask?.cancel()
        
        saveDebounceTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(0.5))
                if !Task.isCancelled {
                    saveProgress()
                }
            } catch {
                
            }
        }
    }
    
    // MARK: - Timer Management
    func toggleTimer() {
        if timerService.isTimerRunning(for: habitId) {
            timerService.stopTimer(for: habitId)
        } else {
            timerService.startTimer(for: habitId, initialProgress: currentProgress)
        }
        isTimerRunning = timerService.isTimerRunning(for: habitId)
        hasChanges = true
        
        saveProgress()
    }
    
    // MARK: - Habit Management
    func toggleFreeze() {
        if habit.isFreezed {
            unfreezeHabit()
        } else {
            freezeHabit()
        }
    }
    
    private func freezeHabit() {
        habit.isFreezed = true
        alertState.isFreezeAlertPresented = true
        updateHabit()
        habitsUpdateService.triggerUpdate()
    }
    
    private func unfreezeHabit() {
        habit.isFreezed = false
        updateHabit()
        habitsUpdateService.triggerUpdate()
    }
    
    func deleteHabit() {
        NotificationManager.shared.cancelNotifications(for: habit)
        modelContext.delete(habit)
        alertState.errorFeedbackTrigger.toggle()
        habitsUpdateService.triggerUpdate()
        
        onHabitDeleted?()
    }
    
    func syncUIStates() {
        let newAlertState = AlertState(
            isResetAlertPresented: alertState.isResetAlertPresented,
            isCountAlertPresented: alertState.isCountAlertPresented,
            isTimeAlertPresented: alertState.isTimeAlertPresented,
            isDeleteAlertPresented: alertState.isDeleteAlertPresented,
            isFreezeAlertPresented: alertState.isFreezeAlertPresented,
            countInputText: alertState.countInputText,
            hoursInputText: alertState.hoursInputText,
            minutesInputText: alertState.minutesInputText,
            successFeedbackTrigger: alertState.successFeedbackTrigger,
            errorFeedbackTrigger: alertState.errorFeedbackTrigger
        )
        
        // Обновляем только если состояние реально изменилось (исключая триггеры)
        if newAlertState != alertState {
            alertState = newAlertState
        }
    }
    
    // MARK: - Progress Actions
    func resetProgress() {
        timerService.resetTimer(for: habitId)
        currentProgress = 0
        updateProgressMetrics()
        hasChanges = true
    }
    
    func completeHabit() {
        let currentValue = timerService.getCurrentProgress(for: habitId)
        var toAdd = habit.goal - currentValue
        
        if habit.type == .time {
            let maxValue = Limits.maxTimeSeconds
            if currentValue + toAdd > maxValue {
                toAdd = maxValue - currentValue
            }
        }
        
        if toAdd > 0 {
            timerService.addProgress(toAdd, for: habitId)
        }
        
        currentProgress = timerService.getCurrentProgress(for: habitId)
        updateProgressMetrics()
        
        saveProgress()
        alertState.successFeedbackTrigger.toggle()
    }
    
    func handleCountInput() {
        guard let value = Int(alertState.countInputText), value > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            alertState.countInputText = ""
            return
        }
        
        let currentValue = timerService.getCurrentProgress(for: habitId)
        
        if currentValue + value > Limits.maxCount {
            let remainingValue = Limits.maxCount - currentValue
            
            if remainingValue > 0 {
                timerService.addProgress(remainingValue, for: habitId)
                alertState.successFeedbackTrigger.toggle()
            } else {
                alertState.errorFeedbackTrigger.toggle()
            }
        } else {
            timerService.addProgress(value, for: habitId)
            alertState.successFeedbackTrigger.toggle()
        }
        
        updateProgress()
        alertState.countInputText = ""
    }
    
    func handleTimeInput() {
        updateProgress()
    }
    
    // MARK: - Save Progress
    func saveProgress() {
        if !hasChanges {
            return
        }
        
        let progress = timerService.getCurrentProgress(for: habitId)
        
        if progress == 0 {
            let existingCompletions = habit.completions.filter {
                Calendar.current.isDate($0.date, inSameDayAs: date)
            }
            
            for completion in existingCompletions {
                modelContext.delete(completion)
            }
            
            do {
                try modelContext.save()
            } catch {
                print("Ошибка при сохранении прогресса (удаление завершений): \(error)")
            }
        } else {
            let existingProgress = habit.progressForDate(date)
            
            if progress != existingProgress {
                if progress < existingProgress {
                    let existingCompletions = habit.completions.filter {
                        Calendar.current.isDate($0.date, inSameDayAs: date)
                    }
                    
                    for completion in existingCompletions {
                        modelContext.delete(completion)
                    }
                    
                    if progress > 0 {
                        habit.addProgress(progress, for: date)
                    }
                } else {
                    habit.addProgress(progress - existingProgress, for: date)
                }
                
                do {
                    try modelContext.save()
                } catch {
                    print("Ошибка при сохранении прогресса: \(error)")
                }
            }
        }
        
        timerService.persistCompletions(for: habitId, in: modelContext, date: date)
        updateStatistics()
        hasChanges = false
        habitsUpdateService.triggerUpdate()
    }
    
    func saveIfNeeded() {
        if hasChanges {
            saveProgress()
        }
    }
    
    func cleanup() {
        onHabitDeleted = nil
        
        saveDebounceTask?.cancel()
        progressObserverTask?.cancel()
        timerStateObserverTask?.cancel()
        saveIfNeeded()
    }
    
    // MARK: - Private Methods
    private func updateHabit() {
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при обновлении привычки: \(error)")
        }
    }
    
    private func updateStatistics() {
        let stats = statsManager.calculateStats(for: habit, upTo: date)
        currentStreak = stats.currentStreak
        bestStreak = stats.bestStreak
        totalCompletions = stats.totalCompletions
    }
}
