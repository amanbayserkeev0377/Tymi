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
    
    // Подписка на обновления прогресса - теперь без @MainActor аннотации
    private var cancellables: Task<Void, Never>? = nil
    
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
        
        // Инициализация только на конкретную дату
        self.currentProgress = habit.progressForDate(date)
        
        setupInitialState()
        setupObservers()
    }
    
    deinit {
        cancellables?.cancel()
    }
    
    // MARK: - Setup
    private func setupInitialState() {
        // Получаем текущий прогресс из прогресс-сервиса или из истории
        if habit.type == .count {
            // Для счетчиков просто берем текущее значение прогресса
            currentProgress = progressService.getCurrentProgress(for: habitId)
        } else {
            // Для таймеров проверяем, запущен ли таймер
            currentProgress = progressService.getCurrentProgress(for: habitId)
            isTimerRunning = progressService.isTimerRunning(for: habitId)
        }
        
        // Если смотрим историческую дату, загружаем исторический прогресс
        if !Calendar.current.isDateInToday(date) {
            let historicalProgress = habit.progressForDate(date)
            
            // Если есть исторический прогресс, устанавливаем его в сервис
            if historicalProgress > 0 {
                // Сбрасываем текущий прогресс и устанавливаем исторический
                progressService.resetProgress(for: habitId)
                progressService.addProgress(historicalProgress, for: habitId)
                currentProgress = historicalProgress
            }
        }
        
        updateProgressMetrics()
    }
    
    // Современный подход с использованием Task и асинхронного наблюдения
    private func setupObservers() {
        // Отменяем существующую задачу, если есть
        cancellables?.cancel()
        
        // Только для сегодняшней даты имеет смысл следить за обновлением прогресса
        if Calendar.current.isDateInToday(date) {
            // Создаем задачу для наблюдения за изменениями в progressService
            cancellables = Task { [weak self] in
                guard let self = self else { return }
                
                // Периодически проверяем обновления (каждые 100 мс)
                while !Task.isCancelled {
                    // Важно! Всю работу с UI-зависимыми свойствами выполняем на главном потоке
                    await MainActor.run {
                        // Получаем актуальный прогресс
                        let newProgress = self.progressService.getCurrentProgress(for: self.habitId)
                        
                        // Обновляем UI только если есть изменения
                        if self.currentProgress != newProgress {
                            self.currentProgress = newProgress
                            self.updateProgressMetrics()
                            self.hasChanges = true
                        }
                        
                        // Обновляем состояние таймера
                        if self.habit.type == .time {
                            let isRunning = self.progressService.isTimerRunning(for: self.habitId)
                            if self.isTimerRunning != isRunning {
                                self.isTimerRunning = isRunning
                            }
                        }
                    }
                    
                    do {
                        try await Task.sleep(for: .milliseconds(100))
                    } catch {
                        break
                    }
                }
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
        
        // Обновляем состояние - не нужно явно обновлять, это произойдет через наблюдение
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
        // Сброс прогресса имеет смысл только для сегодняшней даты
        guard Calendar.current.isDateInToday(date) else {
            alertState.errorFeedbackTrigger.toggle()
            return
        }
        
        progressService.resetProgress(for: habitId)
        currentProgress = 0
        updateProgressMetrics()
        hasChanges = true
        saveProgress()
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
        // Сохраняем прогресс в базу данных для конкретной даты
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
        // Отменяем наблюдение
        cancellables?.cancel()
        cancellables = nil
        
        // Сохраняем прогресс если есть изменения
        if hasChanges {
            saveProgress()
        }
        
        // Очищаем callback
        onHabitDeleted = nil
        
        // Останавливаем таймер если он запущен и требуется остановка
        if stopTimer && isTimerRunning && Calendar.current.isDateInToday(date) {
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
