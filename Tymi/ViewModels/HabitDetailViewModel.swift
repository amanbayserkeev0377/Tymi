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
    
    // Прогресс для текущей даты
    private var habitProgress: HabitProgress
    
    // Добавим новое свойство для локального таймера для прошлых дат
    private var pastDateTimerService: PastDateTimerService?
    
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
        
        // Используем провайдер для получения правильного сервиса по типу привычки
        self.progressService = ProgressServiceProvider.getService(for: habit)
        
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
        
        // Только для сегодняшнего дня проверяем активные таймеры
        if isTodayView && habit.type == .time {
            self.isTimerRunning = progressService.isTimerRunning(for: habitId)
            
            // Если таймер активен, используем его значение
            if isTimerRunning {
                let serviceProgress = progressService.getCurrentProgress(for: habitId)
                // Используем большее из значений
                if serviceProgress > initialProgress {
                    self.currentProgress = serviceProgress
                    self.habitProgress.value = serviceProgress
                } else if initialProgress > 0 && serviceProgress == 0 {
                    // Если в базе есть значение, но сервис сброшен
                    progressService.addProgress(initialProgress, for: habitId)
                }
            } else if initialProgress > 0 {
                // Инициализируем сервис историческими данными
                progressService.resetProgress(for: habitId)
                progressService.addProgress(initialProgress, for: habitId)
            }
        }
        
        updateProgressMetrics()
        setupObservers()
    }
    
    deinit {
        cancellables?.cancel()
    }
    
    // MARK: - Observer Setup
    private func setupObservers() {
           // Отменяем существующую задачу, если есть
           cancellables?.cancel()
           
           // Создаем локальный сервис для прошлых дат, если нужно
           if !isTodayView && habit.type == .time {
               pastDateTimerService = PastDateTimerService(
                   initialProgress: habitProgress.value,
                   habitId: habitId,
                   onUpdate: { [weak self] in
                       guard let self = self else { return }
                       self.updateFromPastDateTimer()
                   }
               )
           }
           
           // Для любой даты устанавливаем наблюдение за прогрессом
           cancellables = Task { [weak self, date] in
               guard let self = self else { return }
               
               // Запоминаем дату, для которой мы наблюдаем
               let observedDate = date
               
               while !Task.isCancelled {
                   await MainActor.run {
                       // Проверяем, что дата не изменилась
                       if self.date == observedDate {
                           if self.isTodayView && self.habit.type == .time {
                               // Для сегодняшнего дня и таймеров обновляем прогресс из глобального сервиса
                               let newProgress = self.progressService.getCurrentProgress(for: self.habitId)
                               
                               // Обновляем UI только если есть изменения
                               if self.currentProgress != newProgress {
                                   self.currentProgress = newProgress
                                   self.habitProgress.value = newProgress
                                   self.habitProgress.isDirty = true
                                   self.updateProgressMetrics()
                                   self.hasChanges = true
                               }
                               
                               // Обновляем состояние таймера
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
    
    private func updateFromPastDateTimer() {
            guard let pastService = pastDateTimerService else { return }
            
            // Получаем текущий прогресс из локального сервиса
            let newProgress = pastService.getCurrentProgress(for: habitId)
            
            // Обновляем UI только если есть изменения
            if currentProgress != newProgress {
                currentProgress = newProgress
                habitProgress.value = newProgress
                habitProgress.isDirty = true
                updateProgressMetrics()
                hasChanges = true
            }
            
            // Обновляем состояние таймера
            let isRunning = pastService.isTimerRunning(for: habitId)
            if isTimerRunning != isRunning {
                isTimerRunning = isRunning
            }
        }
    
    func incrementProgress() {
        if habit.type == .count {
            // Для счетчиков увеличиваем на 1
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
                // Для сегодняшнего дня обновляем таймер
                if isTodayView && isTimerRunning {
                    progressService.stopTimer(for: habitId)
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
            // Для счетчиков уменьшаем на 1
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
            // Для таймеров вычитаем 1 минуту (60 секунд)
            if isTodayView && isTimerRunning {
                progressService.stopTimer(for: habitId)
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
            if isTodayView {
                // Для сегодняшнего дня используем глобальный сервис таймера
                if isTimerRunning {
                    isTimerRunning = false
                    progressService.stopTimer(for: habitId)
                    habitProgress.value = progressService.getCurrentProgress(for: habitId)
                } else {
                    isTimerRunning = true
                    progressService.startTimer(for: habitId, initialProgress: habitProgress.value)
                }
            } else if habit.type == .time {
                // Для прошлых дат используем локальный сервис таймера
                if isTimerRunning {
                    pastDateTimerService?.stopTimer(for: habitId)
                    // isTimerRunning будет обновлен через callback
                } else {
                    pastDateTimerService?.startTimer(for: habitId, initialProgress: habitProgress.value)
                    // isTimerRunning будет обновлен через callback
                }
            }
            
            currentProgress = habitProgress.value
            habitProgress.isDirty = true
            hasChanges = true
            
            // Обязательно сохраняем изменения в базу
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
        habitProgress.value = 0
        habitProgress.isDirty = true
        currentProgress = 0
        
        // Для сегодняшнего дня сбрасываем сервис
        if isTodayView {
            progressService.resetProgress(for: habitId)
        }
        
        updateProgressMetrics()
        hasChanges = true
        saveProgress()
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
                
                // Для сегодняшнего дня обновляем сервис
                if isTodayView {
                    progressService.resetProgress(for: habitId)
                    progressService.addProgress(Limits.maxCount, for: habitId)
                }
                
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
            
            // Для сегодняшнего дня обновляем сервис
            if isTodayView {
                progressService.resetProgress(for: habitId)
                progressService.addProgress(currentProgress, for: habitId)
            }
            
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
            
            if isTodayView {
                // Для сегодняшнего дня используем глобальный сервис
                if isTimerRunning {
                    progressService.stopTimer(for: habitId)
                }
                
                // Проверяем лимит
                if habitProgress.value + secondsToAdd > Limits.maxTimeSeconds {
                    habitProgress.value = Limits.maxTimeSeconds
                    progressService.resetProgress(for: habitId)
                    progressService.addProgress(Limits.maxTimeSeconds, for: habitId)
                } else {
                    habitProgress.value += secondsToAdd
                    progressService.resetProgress(for: habitId)
                    progressService.addProgress(habitProgress.value, for: habitId)
                }
            } else {
                // Для прошлых дат используем локальный сервис или просто обновляем прогресс
                if isTimerRunning && pastDateTimerService != nil {
                    pastDateTimerService?.stopTimer(for: habitId)
                }
                
                // Проверяем лимит
                if habitProgress.value + secondsToAdd > Limits.maxTimeSeconds {
                    habitProgress.value = Limits.maxTimeSeconds
                    if pastDateTimerService != nil {
                        pastDateTimerService?.resetProgress(for: habitId)
                        pastDateTimerService?.addProgress(Limits.maxTimeSeconds, for: habitId)
                    }
                } else {
                    habitProgress.value += secondsToAdd
                    if pastDateTimerService != nil {
                        pastDateTimerService?.resetProgress(for: habitId)
                        pastDateTimerService?.addProgress(habitProgress.value, for: habitId)
                    }
                }
            }
            
            currentProgress = habitProgress.value
            habitProgress.isDirty = true
            
            updateProgressMetrics()
            hasChanges = true
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
                
                guard let habit = habits.first else { return }
                
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
                print("Ошибка сохранения прогресса: \(error)")
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
            
            // Останавливаем локальный таймер для прошлых дат
            if stopTimer && pastDateTimerService != nil {
                for habitId in pastDateTimerService!.progressUpdates.keys {
                    if pastDateTimerService!.isTimerRunning(for: habitId) {
                        pastDateTimerService!.stopTimer(for: habitId)
                    }
                }
                
                // Обнуляем ссылку на сервис
                pastDateTimerService = nil
            }
            
            // Сохраняем прогресс если есть изменения
            if hasChanges || habitProgress.isDirty {
                saveProgress()
            }
            
            // Очищаем callback
            onHabitDeleted = nil
            
            // Останавливаем глобальный таймер при закрытии экрана (только для текущего дня)
            if stopTimer && isTimerRunning && isTodayView {
                progressService.stopTimer(for: habitId)
            }
        }
}
