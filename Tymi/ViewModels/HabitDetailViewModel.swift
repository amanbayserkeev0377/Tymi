import SwiftUI
import SwiftData

@Observable
final class HabitDetailViewModel {
    // MARK: - Dependencies
    private let habit: Habit
    private let habitId: String
    private let date: Date
    var modelContext: ModelContext
    var habitsUpdateService: HabitsUpdateService
    
    // Используем абстрактный сервис вместо конкретного HabitTimerService
    let progressService: ProgressTrackingService
    
    // MARK: - State Properties
    private(set) var currentProgress: Int = 0
    private(set) var completionPercentage: Double = 0
    private(set) var formattedProgress: String = ""
    private(set) var isTimerRunning: Bool = false
    
    // MARK: - UI State
    var isEditSheetPresented = false
    var alertState = AlertState()
    
    private var hasChanges = false
    var onHabitDeleted: (() -> Void)?
    
    private var progressObserver: NSObjectProtocol?
    
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
        
        setupInitialState()
        setupObservers()
    }
    
    // MARK: - Setup
    private func setupInitialState() {
        // Получаем прогресс и обновляем UI
        currentProgress = progressService.getCurrentProgress(for: habitId)
        updateProgressMetrics()
        
        // Проверяем состояние таймера для привычек типа "time"
        if habit.type == .time {
            isTimerRunning = progressService.isTimerRunning(for: habitId)
        }
    }
    
    private func setupObservers() {
        // Один наблюдатель для обновления прогресса привычки
        progressObserver = NotificationCenter.default.addObserver(
            forName: .progressUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let updates = notification.userInfo?["progressUpdates"] as? [String: Int],
                  let progress = updates[self.habitId] else {
                return
            }
            
            // Обновляем состояние на главном потоке
            self.currentProgress = progress
            self.updateProgressMetrics()
            self.hasChanges = true
            
            // Обновляем состояние таймера для привычек типа time
            if self.habit.type == .time {
                self.isTimerRunning = self.progressService.isTimerRunning(for: self.habitId)
            }
        }
    }
    
    // MARK: - Progress Management
    private func updateProgressMetrics() {
        // Рассчитываем процент выполнения
        completionPercentage = habit.goal > 0 ? Double(currentProgress) / Double(habit.goal) : 0
        
        // Форматируем прогресс для отображения
        formattedProgress = habit.type == .count ?
            currentProgress.formattedAsProgress(total: habit.goal) :
            currentProgress.formattedAsTime()
    }
    
    func incrementProgress() {
        if habit.type == .count {
            // Для счетчиков увеличиваем на 1
            let currentValue = progressService.getCurrentProgress(for: habitId)
            if currentValue < Limits.maxCount {
                progressService.addProgress(1, for: habitId)
            } else {
                alertState.errorFeedbackTrigger.toggle()
            }
        } else {
            // Для таймеров добавляем 1 минуту (60 секунд)
            let currentValue = progressService.getCurrentProgress(for: habitId)
            if currentValue + 60 <= Limits.maxTimeSeconds {
                if progressService.isTimerRunning(for: habitId) {
                    progressService.stopTimer(for: habitId)
                }
                progressService.addProgress(60, for: habitId)
            } else {
                // Ограничиваем максимальным значением
                progressService.resetProgress(for: habitId)
                progressService.addProgress(Limits.maxTimeSeconds, for: habitId)
                alertState.successFeedbackTrigger.toggle()
            }
        }
        
        // Сохраняем прогресс в базу данных сразу
        saveProgress()
    }
    
    func decrementProgress() {
        if habit.type == .count {
            // Для счетчиков уменьшаем на 1
            let currentValue = progressService.getCurrentProgress(for: habitId)
            if currentValue > 0 {
                progressService.addProgress(-1, for: habitId)
            }
        } else {
            // Для таймеров вычитаем 1 минуту (60 секунд)
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
        
        // Сохраняем прогресс в базу данных сразу
        saveProgress()
    }
    
    // MARK: - Timer Management
    func toggleTimer() {
        if progressService.isTimerRunning(for: habitId) {
            progressService.stopTimer(for: habitId)
        } else {
            progressService.startTimer(for: habitId, initialProgress: currentProgress)
        }
        
        // Обновляем состояние
        isTimerRunning = progressService.isTimerRunning(for: habitId)
        hasChanges = true
        
        // Сохраняем прогресс
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
    
    // MARK: - Progress Actions
    func resetProgress() {
        progressService.resetProgress(for: habitId)
        currentProgress = 0
        updateProgressMetrics()
        hasChanges = true
    }
    
    func completeHabit() {
        let currentValue = progressService.getCurrentProgress(for: habitId)
        let toAdd = habit.goal - currentValue
        
        if toAdd <= 0 {
            return // Уже завершено
        }
        
        // Добавляем прогресс сразу до цели
        progressService.addProgress(toAdd, for: habitId)
        currentProgress = progressService.getCurrentProgress(for: habitId)
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
        progressService.addProgress(secondsToAdd, for: habitId)
        saveProgress()
        
        // Сбрасываем поля ввода
        alertState.hoursInputText = ""
        alertState.minutesInputText = ""
    }
    
    // MARK: - Save Progress
    func saveProgress() {
        // Сохраняем прогресс в базу данных
        progressService.persistCompletions(for: habitId, in: modelContext, date: date)
        
        // Уведомляем UI об обновлениях
        hasChanges = false
        habitsUpdateService.triggerDelayedUpdate(delay: 0.3)
    }
    
    func saveIfNeeded() {
        if hasChanges {
            saveProgress()
        }
    }
    
    func cleanup(stopTimer: Bool = true) {
        // Удаляем наблюдатели
        if let observer = progressObserver {
            NotificationCenter.default.removeObserver(observer)
            progressObserver = nil
        }
        
        // Сохраняем прогресс если есть изменения
        if hasChanges {
            saveProgress()
        }
        
        // Очищаем callback
        onHabitDeleted = nil
        
        // Останавливаем таймер если он запущен
        if stopTimer && isTimerRunning {
            progressService.stopTimer(for: habitId)
        }
    }
    
    // MARK: - Private Methods
    private func updateHabit() {
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при обновлении привычки: \(error)")
        }
    }
}
