import SwiftUI
import SwiftData

@Observable
@MainActor
final class HabitDetailViewModel {
    // MARK: - Dependencies
    private let habit: Habit
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
        currentProgress = timerService.getCurrentProgress(for: habit.id)
        updateProgressMetrics()
        
        if habit.type == .time {
            isTimerRunning = timerService.isTimerRunning(for: habit.id)
        }
    }
    
    private func setupObservers() {
        // Сначала отменяем предыдущие задачи, если они существуют
        progressObserverTask?.cancel()
        timerStateObserverTask?.cancel()
        
        // Создаем захват weak self для предотвращения утечек памяти
        let habitId = habit.id
        
        // Запускаем наблюдение за прогрессом
        progressObserverTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            for await updates in self.timerService.progressUpdatesSequence {
                // Проверяем, не была ли задача отменена
                if Task.isCancelled { break }
                
                if let progress = updates[habitId] {
                    self.currentProgress = progress
                    self.updateProgressMetrics()
                    self.hasChanges = true
                }
            }
        }
        
        // Запускаем наблюдение за состоянием таймера
        timerStateObserverTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            for await _ in self.timerService.objectWillChangeSequence {
                // Проверяем, не была ли задача отменена
                if Task.isCancelled { break }
                
                self.isTimerRunning = self.timerService.isTimerRunning(for: habitId)
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
            let currentValue = timerService.getCurrentProgress(for: habit.id)
            if currentValue < Limits.maxCount {
                timerService.addProgress(1, for: habit.id)
            } else {
                alertState.errorFeedbackTrigger.toggle()
            }
        } else {
            let currentValue = timerService.getCurrentProgress(for: habit.id)
            if currentValue + 60 <= Limits.maxTimeSeconds {
                if timerService.isTimerRunning(for: habit.id) {
                    timerService.stopTimer(for: habit.id)
                }
                timerService.addProgress(60, for: habit.id)
            } else {
                timerService.resetTimer(for: habit.id)
                timerService.addProgress(Limits.maxTimeSeconds, for: habit.id)
                
                alertState.successFeedbackTrigger.toggle()
            }
        }
        updateProgress()
    }
    
    func decrementProgress() {
        if habit.type == .count {
            let currentValue = timerService.getCurrentProgress(for: habit.id)
            if currentValue > 0 {
                timerService.addProgress(-1, for: habit.id)
            }
        } else {
            if timerService.isTimerRunning(for: habit.id) {
                timerService.stopTimer(for: habit.id)
            }
            
            let currentValue = timerService.getCurrentProgress(for: habit.id)
            if currentValue >= 60 {
                timerService.addProgress(-60, for: habit.id)
            } else if currentValue > 0 {
                timerService.resetTimer(for: habit.id)
            }
        }
        updateProgress()
    }
    
    private func updateProgress() {
        currentProgress = timerService.getCurrentProgress(for: habit.id)
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
        if timerService.isTimerRunning(for: habit.id) {
            timerService.stopTimer(for: habit.id)
        } else {
            timerService.startTimer(for: habit.id, initialProgress: currentProgress)
        }
        isTimerRunning = timerService.isTimerRunning(for: habit.id)
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
        timerService.resetTimer(for: habit.id)
        currentProgress = 0
        updateProgressMetrics()
        hasChanges = true
    }
    
    func completeHabit() {
        let currentValue = timerService.getCurrentProgress(for: habit.id)
        var toAdd = habit.goal - currentValue
        
        if habit.type == .time {
            let maxValue = Limits.maxTimeSeconds
            if currentValue + toAdd > maxValue {
                toAdd = maxValue - currentValue
            }
        }
        
        if toAdd > 0 {
            timerService.addProgress(toAdd, for: habit.id)
        }
        
        currentProgress = timerService.getCurrentProgress(for: habit.id)
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
        
        let currentValue = timerService.getCurrentProgress(for: habit.id)
        
        if currentValue + value > Limits.maxCount {
            let remainingValue = Limits.maxCount - currentValue
            
            if remainingValue > 0 {
                timerService.addProgress(remainingValue, for: habit.id)
                alertState.successFeedbackTrigger.toggle()
            } else {
                alertState.errorFeedbackTrigger.toggle()
            }
        } else {
            timerService.addProgress(value, for: habit.id)
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
        
        let progress = timerService.getCurrentProgress(for: habit.id)
        
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
        
        timerService.persistCompletions(for: habit.id, in: modelContext, date: date)
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
