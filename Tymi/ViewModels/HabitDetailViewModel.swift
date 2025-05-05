import SwiftUI
import SwiftData
import Combine

@MainActor
class HabitDetailViewModel: ObservableObject {
    // MARK: - Dependencies
    private let habit: Habit
    private let date: Date
    var modelContext: ModelContext
    var habitsUpdateService: HabitsUpdateService
    var timerService: HabitTimerService
    private let statsManager: StatsManager
    
    // MARK: - Published Properties
    @Published private(set) var currentProgress: Int = 0
    @Published private(set) var completionPercentage: Double = 0
    @Published private(set) var formattedProgress: String = ""
    @Published private(set) var isTimerRunning: Bool = false
    
    // MARK: - Statistics Properties
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var bestStreak: Int = 0
    @Published private(set) var totalCompletions: Int = 0
    
    // MARK: - State Properties
    @Published var isEditSheetPresented = false
    @Published var alertState = AlertState()
    
    // Флаг для отслеживания были ли изменения, требующие сохранения
    private var hasChanges = false
    
    private var cancellables = Set<AnyCancellable>()
    
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
        setupSubscriptions()
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
    
    private func setupSubscriptions() {
        // Подписываемся на изменения прогресса
        timerService.$progressUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updates in
                guard let self = self,
                      let progress = updates[self.habit.id] else { return }
                self.currentProgress = progress
                self.updateProgressMetrics()
                self.hasChanges = true
            }
            .store(in: &cancellables)
        
        // Подписываемся на изменения состояния таймера
        timerService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.isTimerRunning = self.timerService.isTimerRunning(for: self.habit.id)
            }
            .store(in: &cancellables)
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
            timerService.addProgress(1, for: habit.id)
        } else {
            if timerService.isTimerRunning(for: habit.id) {
                timerService.stopTimer(for: habit.id)
            }
            timerService.addProgress(60, for: habit.id)
        }
        updateProgress()
    }
    
    func decrementProgress() {
        if habit.type == .count {
            let currentProgress = timerService.getCurrentProgress(for: habit.id)
            if currentProgress > 0 {
                timerService.addProgress(-1, for: habit.id)
            }
        } else {
            if timerService.isTimerRunning(for: habit.id) {
                timerService.stopTimer(for: habit.id)
            }
            
            let currentProgress = timerService.getCurrentProgress(for: habit.id)
            if currentProgress >= 60 {
                timerService.addProgress(-60, for: habit.id)
            } else if currentProgress > 0 {
                timerService.resetTimer(for: habit.id)
            }
        }
        updateProgress()
    }
    
    private func updateProgress() {
        // Напрямую запрашиваем текущий прогресс
        currentProgress = timerService.getCurrentProgress(for: habit.id)
        updateProgressMetrics()
        hasChanges = true
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
        // Сразу уведомляем, т.к. это важное изменение
        habitsUpdateService.triggerUpdate()
    }
    
    private func unfreezeHabit() {
        habit.isFreezed = false
        updateHabit()
        // Сразу уведомляем, т.к. это важное изменение
        habitsUpdateService.triggerUpdate()
    }
    
    func deleteHabit() {
        NotificationManager.shared.cancelNotifications(for: habit)
        modelContext.delete(habit)
        alertState.errorFeedbackTrigger.toggle()
        // Сразу уведомляем, т.к. это важное изменение
        habitsUpdateService.triggerUpdate()
    }
    
    // MARK: - Progress Actions
    func resetProgress() {
        // 1. Сбрасываем таймер
        timerService.resetTimer(for: habit.id)
        
        // 2. Обновляем локальные данные
        currentProgress = 0
        updateProgressMetrics()
        
        // Помечаем, что были изменения
        hasChanges = true
        
        // Но НЕ обновляем базу данных и не отправляем уведомления сейчас
        // Это будет сделано только при закрытии представления
    }
    
    func completeHabit() {
        // Получаем текущий прогресс из timerService
        let currentValue = timerService.getCurrentProgress(for: habit.id)
        let toAdd = habit.goal - currentValue
        
        if toAdd > 0 {
            timerService.addProgress(toAdd, for: habit.id)
        }
        
        // Обновляем прогресс напрямую
        currentProgress = timerService.getCurrentProgress(for: habit.id)
        updateProgressMetrics()
        
        // Помечаем, что были изменения
        hasChanges = true
        
        // Звуковая обратная связь
        alertState.successFeedbackTrigger.toggle()
        
        // Но НЕ обновляем базу данных и не отправляем уведомления сейчас
    }
    
    // MARK: - Input Handling
    func handleCountInput() {
        if let value = Int(alertState.countInputText), value > 0 {
            timerService.addProgress(value, for: habit.id)
            alertState.successFeedbackTrigger.toggle()
            updateProgress()
        }
        alertState.countInputText = ""
    }
    
    func handleTimeInput() {
        let minutes = Int(alertState.minutesInputText) ?? 0
        let hours = Int(alertState.hoursInputText) ?? 0
        let totalSeconds = (hours * 3600) + (minutes * 60)
        
        if totalSeconds > 0 {
            if timerService.isTimerRunning(for: habit.id) {
                timerService.stopTimer(for: habit.id)
            }
            timerService.addProgress(totalSeconds, for: habit.id)
            alertState.successFeedbackTrigger.toggle()
            updateProgress()
        }
        
        alertState.minutesInputText = ""
        alertState.hoursInputText = ""
    }
    
    // MARK: - Save Progress
    func saveProgress() {
        // Если не было изменений, выходим
        if !hasChanges {
            return
        }
        
        // Получаем текущий прогресс из timerService
        let progress = timerService.getCurrentProgress(for: habit.id)
        
        // Обрабатываем случай сброса прогресса
        if progress == 0 {
            // Удаляем все записи о прогрессе для текущего дня
            let existingCompletions = habit.completions.filter {
                Calendar.current.isDate($0.date, inSameDayAs: date)
            }
            
            for completion in existingCompletions {
                modelContext.delete(completion)
            }
            
            try? modelContext.save()
        } else {
            // Проверяем существующий прогресс
            let existingProgress = habit.progressForDate(date)
            
            // Если прогресс изменился, обновляем данные
            if progress != existingProgress {
                // Если текущий прогресс меньше существующего, удаляем записи и создаем новую
                if progress < existingProgress {
                    let existingCompletions = habit.completions.filter {
                        Calendar.current.isDate($0.date, inSameDayAs: date)
                    }
                    
                    for completion in existingCompletions {
                        modelContext.delete(completion)
                    }
                    
                    // Если прогресс > 0, добавляем новую запись
                    if progress > 0 {
                        habit.addProgress(progress, for: date)
                    }
                } else {
                    // Если прогресс больше, просто добавляем разницу
                    habit.addProgress(progress - existingProgress, for: date)
                }
                
                try? modelContext.save()
            }
        }
        
        // Также используем стандартный метод для сохранения (на случай, если он что-то еще делает)
        timerService.persistCompletions(for: habit.id, in: modelContext, date: date)
        
        // Обновляем статистику
        updateStatistics()
        
        // Сбрасываем флаг изменений
        hasChanges = false
        
        // Отправляем уведомление об обновлении
        habitsUpdateService.triggerUpdate()
    }
    
    // MARK: - Private Methods
    private func updateHabit() {
        try? modelContext.save()
    }
    
    private func updateStatistics() {
        let stats = statsManager.calculateStats(for: habit, upTo: date)
        currentStreak = stats.currentStreak
        bestStreak = stats.bestStreak
        totalCompletions = stats.totalCompletions
    }
}
