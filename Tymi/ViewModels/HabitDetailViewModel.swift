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
    var progressService: ProgressTrackingService
    
    // MARK: - State Properties
    private(set) var currentProgress: Int = 0
    private(set) var completionPercentage: Double = 0
    private(set) var formattedProgress: String = ""
    private(set) var isTimerRunning: Bool = false
    
    // Прогресс для текущей даты
    private var habitProgress: HabitProgress
    
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
        
        // Инициализация прогресса из базы данных
        let initialProgress = habit.progressForDate(date)
        
        // Создаем объект прогресса для этой даты
        self.habitProgress = HabitProgress(
            habitId: habitId,
            date: date,
            value: initialProgress
        )
        
        // Обновляем текущий прогресс
        self.currentProgress = initialProgress
        
        // Проверяем, является ли дата текущей
        let isToday = Calendar.current.isDateInToday(date)
        
        // Временно инициализируем сервис
        // Это предотвращает ошибку с неинициализированным свойством
        self.progressService = ProgressServiceProvider.getService(for: habit)
        
        updateProgressMetrics() // Инициализируем остальные свойства
        
        // Затем переприсваиваем правильный сервис в зависимости от даты
        if !isToday && habit.type == .time {
            // Для прошлых дат и типа time используем локальный сервис
            let localService = ProgressServiceProvider.getLocalService(
                for: habit,
                date: date,
                initialProgress: initialProgress,
                onUpdate: { [weak self] in
                    self?.updateFromService()
                }
            )
            self.progressService = localService
        }
        
        // Теперь, когда все свойства инициализированы, можем выполнить дополнительную настройку
        if isToday && habit.type == .time {
            self.isTimerRunning = self.progressService.isTimerRunning(for: habitId)
            
            // Если таймер активен, используем его значение
            if self.isTimerRunning {
                let serviceProgress = self.progressService.getCurrentProgress(for: habitId)
                // Используем большее из значений
                if serviceProgress > initialProgress {
                    self.currentProgress = serviceProgress
                    self.habitProgress.value = serviceProgress
                } else if initialProgress > 0 && serviceProgress == 0 {
                    // Если в базе есть значение, но сервис сброшен
                    self.progressService.addProgress(initialProgress, for: habitId)
                }
            } else if initialProgress > 0 {
                // Инициализируем сервис историческими данными
                self.progressService.resetProgress(for: habitId)
                self.progressService.addProgress(initialProgress, for: habitId)
            }
        }
        
        setupObservers()
    }
    
    deinit {
        cancellables?.cancel()
    }
    
    // MARK: - Observer Setup
    private func setupObservers() {
        cancellables?.cancel()
        
        cancellables = Task { [weak self, date] in
            guard let self = self else { return }
            
            let observedDate = date
            
            while !Task.isCancelled {
                await MainActor.run {
                    if self.date == observedDate {
                        // ИЗМЕНЕНИЕ: Удаляем проверку на isTodayView, чтобы обновлять
                        // UI для любых дат с запущенным таймером
                        if self.habit.type == .time && self.isTimerRunning {
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
        // Рассчитываем процент выполнения
        completionPercentage = habit.goal > 0 ? Double(currentProgress) / Double(habit.goal) : 0
        
        // Форматируем прогресс для отображения
        formattedProgress = habit.type == .count ?
        currentProgress.formattedAsProgress(total: habit.goal) :
        currentProgress.formattedAsTime()
    }
    
    private func updateFromService() {
        // Получаем текущий прогресс из сервиса
        let newProgress = progressService.getCurrentProgress(for: habitId)
        
        // Обновляем UI только если есть изменения
        if currentProgress != newProgress {
            currentProgress = newProgress
            habitProgress.value = newProgress
            habitProgress.isDirty = true
            updateProgressMetrics()
            hasChanges = true
        }
        
        // Обновляем состояние таймера
        let isRunning = progressService.isTimerRunning(for: habitId)
        if isTimerRunning != isRunning {
            isTimerRunning = isRunning
        }
    }
    
    func incrementProgress() {
        if habit.type == .count {
            // Код для счетчиков остается без изменений
            if habitProgress.value < Limits.maxCount {
                habitProgress.value += 1
                habitProgress.isDirty = true
                currentProgress = habitProgress.value
                
                // Для сегодняшнего дня обновляем сервис (для виджетов и т.д.)
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
            // Для таймеров добавляем 1 минуту (60 секунд)
            if habitProgress.value + 60 <= Limits.maxTimeSeconds {
                // ИЗМЕНЕНИЕ: Убрана проверка на isTodayView
                // Если таймер запущен, останавливаем его независимо от даты
                if isTimerRunning {
                    progressService.stopTimer(for: habitId)
                    isTimerRunning = false  // Добавлено явное обновление состояния
                }
                
                habitProgress.value += 60
                habitProgress.isDirty = true
                currentProgress = habitProgress.value
                
                // Для сегодняшнего дня обновляем сервис
                if isTodayView {
                    progressService.resetProgress(for: habitId)
                    progressService.addProgress(currentProgress, for: habitId)
                }
                
                updateProgressMetrics()
                hasChanges = true
            } else {
                // Ограничиваем максимальным значением
                habitProgress.value = Limits.maxTimeSeconds
                habitProgress.isDirty = true
                currentProgress = Limits.maxTimeSeconds
                
                // Если таймер запущен, останавливаем его независимо от даты
                if isTimerRunning {
                    progressService.stopTimer(for: habitId)
                    isTimerRunning = false  // Добавлено явное обновление состояния
                }
                
                // Для сегодняшнего дня обновляем сервис
                if isTodayView {
                    progressService.resetProgress(for: habitId)
                    progressService.addProgress(Limits.maxTimeSeconds, for: habitId)
                }
                
                updateProgressMetrics()
                hasChanges = true
                alertState.successFeedbackTrigger.toggle()
            }
        }
        
        // Сохраняем прогресс в базу данных
        saveProgress()
    }
    
    func decrementProgress() {
        if habit.type == .count {
            // Код для счетчиков остается без изменений
            if habitProgress.value > 0 {
                habitProgress.value -= 1
                habitProgress.isDirty = true
                currentProgress = habitProgress.value
                
                // Для сегодняшнего дня обновляем сервис
                if isTodayView {
                    progressService.resetProgress(for: habitId)
                    progressService.addProgress(currentProgress, for: habitId)
                }
                
                updateProgressMetrics()
                hasChanges = true
            }
        } else {
            // ИЗМЕНЕНИЕ: Убрана проверка на isTodayView
            if isTimerRunning {
                progressService.stopTimer(for: habitId)
                isTimerRunning = false  // Явное обновление состояния
            }
            
            if habitProgress.value >= 60 {
                habitProgress.value -= 60
                habitProgress.isDirty = true
                currentProgress = habitProgress.value
                
                // Для сегодняшнего дня обновляем сервис
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
                
                // Для сегодняшнего дня обновляем сервис
                if isTodayView {
                    progressService.resetProgress(for: habitId)
                }
                
                updateProgressMetrics()
                hasChanges = true
            }
        }
        
        // Сохраняем прогресс в базу данных
        saveProgress()
    }
    
    // MARK: - Timer Management
    func toggleTimer() {
        if isTimerRunning {
            // Остановка таймера
            isTimerRunning = false
            progressService.stopTimer(for: habitId)
            habitProgress.value = progressService.getCurrentProgress(for: habitId)
        } else {
            // Запуск таймера
            // Сначала получаем текущее значение прогресса
            let currentValue = habitProgress.value
            
            // Особая обработка для прошлых дат
            if !isTodayView && habit.type == .time {
                // Сбрасываем прогресс в сервисе
                progressService.resetProgress(for: habitId)
                
                // Устанавливаем текущее значение прогресса
                if currentValue > 0 {
                    progressService.addProgress(currentValue, for: habitId)
                }
            }
            
            // Запускаем таймер с текущим значением
            isTimerRunning = true
            progressService.startTimer(for: habitId, initialProgress: currentValue)
            
            // Проверяем, что значение не сбросилось
            let newProgress = progressService.getCurrentProgress(for: habitId)
            if newProgress < currentValue {
                // Если значение неожиданно уменьшилось, восстанавливаем его
                progressService.stopTimer(for: habitId)
                progressService.resetProgress(for: habitId)
                progressService.addProgress(currentValue, for: habitId)
                
                // Перезапускаем таймер
                isTimerRunning = true
                progressService.startTimer(for: habitId, initialProgress: currentValue)
            }
        }
        
        // Синхронизируем текущий прогресс с сервисом
        currentProgress = progressService.getCurrentProgress(for: habitId)
        habitProgress.value = currentProgress
        
        habitProgress.isDirty = true
        hasChanges = true
        saveProgress()
    }
    
    func addTimeValue(_ seconds: Int) {
            // Останавливаем таймер, если он был запущен
            if isTimerRunning {
                isTimerRunning = false
                if isTodayView {
                    progressService.stopTimer(for: habitId)
                }
            }
            
            // Для любой даты обновляем локальный прогресс
            habitProgress.value += seconds
            habitProgress.isDirty = true
            currentProgress = habitProgress.value
            
            // Для сегодняшнего дня дополнительно обновляем сервис
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
    
    // MARK: - Progress Actions
    func resetProgress() {
        // Если таймер запущен, останавливаем его
        if isTimerRunning {
            progressService.stopTimer(for: habitId)
            isTimerRunning = false
        }
        
        // Сбрасываем прогресс в сервисе
        progressService.resetProgress(for: habitId)
        
        // Обновляем локальные значения
        habitProgress.value = 0
        habitProgress.isDirty = true
        currentProgress = 0
        
        updateProgressMetrics()
        hasChanges = true
        saveProgress()
        
        // Двойная проверка для прошлых дат
        if !isTodayView {
            // Проверяем, действительно ли сбросился прогресс
            let serviceProgress = progressService.getCurrentProgress(for: habitId)
            if serviceProgress > 0 {
                // Если прогресс не сбросился, пытаемся сбросить его еще раз
                progressService.resetProgress(for: habitId)
                
                // Явно сохраняем в базу данных
                Task { @MainActor in
                    saveProgress()
                }
            }
        }
    }
    
    func completeHabit() {
        if currentProgress >= habit.goal {
            return // Уже завершено
        }
        
        // Устанавливаем прогресс равным целевому значению
        habitProgress.value = habit.goal
        habitProgress.isDirty = true
        currentProgress = habit.goal
        
        // Для сегодняшнего дня обновляем сервис
        if isTodayView {
            progressService.resetProgress(for: habitId)
            progressService.addProgress(habit.goal, for: habitId)
        }
        
        updateProgressMetrics()
        hasChanges = true
        saveProgress()
        alertState.successFeedbackTrigger.toggle()
    }
    
    func handleCountInput() {
        guard let value = Int(alertState.countInputText), value > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            alertState.countInputText = ""
            return
        }
        
        // Проверяем лимит
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
        
        // Останавливаем таймер, если он был запущен
        if isTimerRunning {
            progressService.stopTimer(for: habitId)
            isTimerRunning = false
        }
        
        // ВАЖНОЕ ИЗМЕНЕНИЕ: Не добавляем прогресс здесь напрямую,
        // просто обновляем локальные значения
        
        // Проверяем лимит
        if habitProgress.value + secondsToAdd > Limits.maxTimeSeconds {
            let remainingSeconds = Limits.maxTimeSeconds - habitProgress.value
            
            if remainingSeconds > 0 {
                habitProgress.value = Limits.maxTimeSeconds
                habitProgress.isDirty = true
                currentProgress = Limits.maxTimeSeconds
                
                // Обновляем сервис (здесь сбрасываем и устанавливаем новое значение)
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
            
            // Обновляем сервис (здесь сбрасываем и устанавливаем новое значение)
            if isTodayView {
                progressService.resetProgress(for: habitId)
                progressService.addProgress(habitProgress.value, for: habitId)
            }
            
            updateProgressMetrics()
            hasChanges = true
            alertState.successFeedbackTrigger.toggle()
        }
        
        saveProgress()
        
        // Сбрасываем поля ввода
        alertState.hoursInputText = ""
        alertState.minutesInputText = ""
    }
    
    // MARK: - Save Progress
    func saveProgress() {
        if habitProgress.isDirty {
            // Сохраняем только если данные изменились
            do {
                // Находим привычку по UUID
                let uuid = habit.uuid
                let descriptor = FetchDescriptor<Habit>(predicate: #Predicate<Habit> { h in
                    h.uuid == uuid
                })
                
                let habits = try modelContext.fetch(descriptor)
                
                guard let habit = habits.first else {
                    return
                }
                
                // Используем дату из habitProgress
                let targetDate = habitProgress.date
                
                // Удаляем старые записи за этот день
                let oldCompletions = habit.completions.filter {
                    Calendar.current.isDate($0.date, inSameDayAs: targetDate)
                }
                
                
                for completion in oldCompletions {
                    modelContext.delete(completion)
                }
                
                // Добавляем новую запись
                if habitProgress.value > 0 {
                    let newCompletion = HabitCompletion(
                        date: targetDate,
                        value: habitProgress.value,
                        habit: habit
                    )
                    habit.completions.append(newCompletion)
                }
                
                try modelContext.save()
                
                // Сбрасываем флаг изменений
                habitProgress.isDirty = false
                hasChanges = false
                
                // Уведомляем UI об обновлениях
                habitsUpdateService.triggerDelayedUpdate(delay: 0.3)
            } catch {
            }
        }
    }
    
    func saveIfNeeded() {
        if hasChanges || habitProgress.isDirty {
            saveProgress()
        }
    }
    
    func cleanup(stopTimer: Bool = true) {
        // Отменяем наблюдение
        cancellables?.cancel()
        cancellables = nil
        
        // Сохраняем прогресс если есть изменения
        if hasChanges || habitProgress.isDirty {
            saveProgress()
        }
        
        // Очищаем callback
        onHabitDeleted = nil
        
        // Останавливаем таймер при закрытии экрана, если он активен
        if stopTimer && isTimerRunning {
            progressService.stopTimer(for: habitId)
        }
    }
}
