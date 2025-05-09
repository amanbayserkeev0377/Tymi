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
    
    // Используем абстрактный сервис вместо конкретного HabitTimerService
    let progressService: ProgressTrackingService
    
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
        
        // Используем провайдер для получения правильного сервиса по типу привычки
        self.progressService = ProgressServiceProvider.getService(for: habit)
        
        self.statsManager = StatsManager(modelContext: modelContext)
        
        setupInitialState()
        setupObservers()
        updateStatistics()
    }
    
    // MARK: - Setup
    private func setupInitialState() {
        currentProgress = progressService.getCurrentProgress(for: habitId)
        updateProgressMetrics()
        
        if habit.type == .time {
            isTimerRunning = progressService.isTimerRunning(for: habitId)
        }
    }
    
    private func setupObservers() {
        // Сначала отменяем предыдущие задачи, если они существуют
        progressObserverTask?.cancel()
        timerStateObserverTask?.cancel()
            
        // Запускаем наблюдение за прогрессом
        progressObserverTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            for await updates in self.progressService.progressUpdatesSequence {
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
            
            for await _ in self.progressService.objectWillChangeSequence {
                // Проверяем, не была ли задача отменена
                if Task.isCancelled { break }
                
                await MainActor.run {
                    self.isTimerRunning = self.progressService.isTimerRunning(for: self.habitId)
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
            let currentValue = progressService.getCurrentProgress(for: habitId)
            if currentValue < Limits.maxCount {
                progressService.addProgress(1, for: habitId)
            } else {
                alertState.errorFeedbackTrigger.toggle()
            }
        } else {
            let currentValue = progressService.getCurrentProgress(for: habitId)
            if currentValue + 60 <= Limits.maxTimeSeconds {
                if progressService.isTimerRunning(for: habitId) {
                    progressService.stopTimer(for: habitId)
                }
                progressService.addProgress(60, for: habitId)
            } else {
                progressService.resetProgress(for: habitId)
                progressService.addProgress(Limits.maxTimeSeconds, for: habitId)
                
                alertState.successFeedbackTrigger.toggle()
            }
        }
        updateProgress()
    }
    
    func decrementProgress() {
        if habit.type == .count {
            let currentValue = progressService.getCurrentProgress(for: habitId)
            if currentValue > 0 {
                progressService.addProgress(-1, for: habitId)
            }
        } else {
            if progressService.isTimerRunning(for: habitId) {
                progressService.stopTimer(for: habitId)
            }
            
            let currentValue = progressService.getCurrentProgress(for: habitId)
            if currentValue >= 60 {
                progressService.addProgress(-60, for: habitId)
            } else if currentValue > 0 {
                progressService.resetProgress(for: habitId)
            }
        }
        updateProgress()
    }
    
    private func updateProgress() {
        currentProgress = progressService.getCurrentProgress(for: habitId)
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
        if progressService.isTimerRunning(for: habitId) {
            progressService.stopTimer(for: habitId)
        } else {
            progressService.startTimer(for: habitId, initialProgress: currentProgress)
        }
        isTimerRunning = progressService.isTimerRunning(for: habitId)
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
        progressService.resetProgress(for: habitId)
        currentProgress = 0
        updateProgressMetrics()
        hasChanges = true
    }
    
    func completeHabit() {
        Task { @MainActor in
            let currentValue = progressService.getCurrentProgress(for: habitId)
            var toAdd = habit.goal - currentValue
            
            // Ограничиваем максимальное значение для предотвращения зависаний
            let maxSingleAdd = 1000 // Разумное ограничение для одной операции
            toAdd = min(toAdd, maxSingleAdd)
            
            if habit.type == .time {
                let maxValue = Limits.maxTimeSeconds
                if currentValue + toAdd > maxValue {
                    toAdd = maxValue - currentValue
                }
            }
            
            // Добавляем прогресс чанками, чтобы предотвратить зависание UI
            if toAdd > 0 {
                let chunkSize = 100
                var remainingValue = toAdd
                
                while remainingValue > 0 {
                    let chunk = min(remainingValue, chunkSize)
                    progressService.addProgress(chunk, for: habitId)
                    remainingValue -= chunk
                    
                    // Даем возможность UI обновиться между операциями
                    if remainingValue > 0 {
                        try? await Task.sleep(for: .nanoseconds(1_000_000)) // 1 миллисекунда
                    }
                }
            }
            
            currentProgress = progressService.getCurrentProgress(for: habitId)
            updateProgressMetrics()
            
            saveProgress()
            alertState.successFeedbackTrigger.toggle()
        }
    }
    
    func handleCountInput() {
        guard let value = Int(alertState.countInputText), value > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            alertState.countInputText = ""
            return
        }
        
        let currentValue = progressService.getCurrentProgress(for: habitId)
        
        if currentValue + value > Limits.maxCount {
            let remainingValue = Limits.maxCount - currentValue
            
            if remainingValue > 0 {
                progressService.addProgress(remainingValue, for: habitId)
                alertState.successFeedbackTrigger.toggle()
            } else {
                alertState.errorFeedbackTrigger.toggle()
            }
        } else {
            progressService.addProgress(value, for: habitId)
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
        // Проверяем необходимость сохранения
        if !hasChanges {
            return
        }
        
        // Используем Task для асинхронной работы
        Task { @MainActor in
            // Сохраняем в базу данных через соответствующий сервис
            progressService.persistCompletions(for: habitId, in: modelContext, date: date)
            
            // Обновляем статистику и UI
            updateStatistics()
            hasChanges = false
            habitsUpdateService.triggerDelayedUpdate(delay: 0.3)
        }
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
