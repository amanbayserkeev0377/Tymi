import SwiftUI
import Combine

class HabitDetailViewModel: ObservableObject {
    let habit: Habit
    
    @Published var progress: Double = 0
    @Published var currentValue: Double = 0
    @Published var isCompleted: Bool = false
    @Published var isExpanded: Bool = false
    @Published var showManualInput: Bool = false
    @Published var isPlaying: Bool = false
    @Published var canUndo: Bool = false
    @Published var showOptions: Bool = false
    
    var onUpdate: ((Double) -> Void)?
    var onComplete: (() -> Void)?
    
    private struct ProgressAction {
        let oldValue: Double
        let newValue: Double
        let type: ActionType
        let timestamp: Date
        
        enum ActionType: Equatable {
            case increment(amount: Double)
            case manualInput
            case reset
        }
    }
    
    private var timer: Timer?
    private var lastTimerUpdate: Date?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var lastAction: ProgressAction?
    private let maxUndoTimeInterval: TimeInterval = 300 // 5 minutes
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private struct HabitState: Codable {
        let habitId: UUID
        let currentValue: Double
        let isCompleted: Bool
        let lastUpdate: Date
    }
    
    private var userDefaults: UserDefaults {
        UserDefaults.standard
    }
    
    private var stateKey: String {
        "habit_state_\(habit.id.uuidString)"
    }
    
    private var wasRunningBeforeBackground = false
    private var startTime: Date?
    
    init(habit: Habit) {
        self.habit = habit
        loadState()
        feedbackGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    // MARK: - Public Methods
    
    func increment(by amount: Double = 1) {
        guard amount > 0 else { return }
        
        if isPlaying {
            pauseTimer()
        }
        
        let oldValue = currentValue
        let increment = habit.type == .time ? amount * 60 : amount
        
        // Защита от переполнения
        let newValue = currentValue + increment
        guard !newValue.isInfinite && !newValue.isNaN else { return }
        
        currentValue = newValue
        
        saveAction(
            .init(
                oldValue: oldValue,
                newValue: currentValue,
                type: .increment(amount: amount),
                timestamp: Date()
            )
        )
        
        feedbackGenerator.impactOccurred()
        updateProgress()
        saveState()
    }
    
    func decrement(by amount: Double = 1) {
        guard amount > 0 else { return }
        
        if isPlaying {
            pauseTimer()
        }
        
        let decrement = habit.type == .time ? amount * 60 : amount
        let oldValue = currentValue
        currentValue = max(0, currentValue - decrement)
        
        if oldValue != currentValue {
            feedbackGenerator.impactOccurred()
        }
        
        updateProgress()
        saveState()
    }
    
    func setValue(_ value: Double) {
        guard !value.isInfinite && !value.isNaN && value >= 0 else { return }
        
        if isPlaying {
            pauseTimer()
        }
        
        let oldValue = currentValue
        let newValue = habit.type == .time ? value * 60 : value
        currentValue = max(0, newValue)
        
        if oldValue != currentValue {
            feedbackGenerator.impactOccurred()
        }
        
        saveAction(
            .init(
                oldValue: oldValue,
                newValue: currentValue,
                type: .manualInput,
                timestamp: Date()
            )
        )
        
        updateProgress()
        saveState()
    }
    
    func reset() {
        if isPlaying {
            pauseTimer()
        }
        
        let oldValue = currentValue
        currentValue = 0
        
        if oldValue != 0 {
            notificationGenerator.notificationOccurred(.warning)
        }
        
        saveAction(
            .init(
                oldValue: oldValue,
                newValue: 0,
                type: .reset,
                timestamp: Date()
            )
        )
        
        updateProgress()
        saveState()
    }
    
    func toggleTimer() {
        if isCompleted {
            pauseTimer()
            return
        }
        
        if isPlaying {
            pauseTimer()
        } else {
            startTimer()
        }
        feedbackGenerator.impactOccurred()
    }
    
    func undo() {
        guard let action = lastAction,
              Date().timeIntervalSince(action.timestamp) <= maxUndoTimeInterval
        else {
            canUndo = false
            return
        }
        
        switch action.type {
        case .increment, .manualInput:
            currentValue = action.oldValue
            lastAction = nil
            canUndo = false
            
            feedbackGenerator.impactOccurred()
            updateProgress()
            saveState()
        case .reset:
            canUndo = false
        }
    }
    
    // MARK: - App Lifecycle
    func onAppear() {
        resumeTimerIfNeeded()
    }
    
    func onDisappear() {
        pauseTimerIfNeeded()
    }
    
    // MARK: - Timer Management
    private func resumeTimerIfNeeded() {
        guard habit.type == .time, !isCompleted else { return }
        isPlaying = true
        startTime = Date()
    }
    
    private func pauseTimerIfNeeded() {
        guard habit.type == .time else { return }
        isPlaying = false
        if let start = startTime {
            let elapsed = Date().timeIntervalSince(start)
            currentValue += elapsed
            startTime = nil
        }
    }
    
    // MARK: - Private Methods
    
    private func startTimer() {
        guard !isCompleted else { return }
        guard habit.type == .time else { return }
        
        isPlaying = true
        lastTimerUpdate = Date()
        startBackgroundTask()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let now = Date()
            guard let last = self.lastTimerUpdate else {
                self.lastTimerUpdate = now
                return
            }
            
            // Проверяем, не прошло ли слишком много времени
            let timeDiff = now.timeIntervalSince(last)
            if timeDiff > 60 {
                self.lastTimerUpdate = now
                return
            }
            
            // Ограничиваем максимальный интервал
            let cappedTimeDiff = min(timeDiff, 1.0)
            let newValue = self.currentValue + cappedTimeDiff
            
            // Защита от переполнения
            guard newValue.isFinite && !newValue.isNaN else {
                self.pauseTimer()
                return
            }
            
            let oldValue = self.currentValue
            self.currentValue = newValue
            self.lastTimerUpdate = now
            
            // Обновляем только при реальных изменениях
            if oldValue != newValue {
                self.updateProgress()
            }
        }
        
        RunLoop.main.add(timer!, forMode: .common)
        feedbackGenerator.impactOccurred()
    }
    
    private func pauseTimer() {
        guard isPlaying else { return }
        
        isPlaying = false
        lastTimerUpdate = nil
        timer?.invalidate()
        timer = nil
        endBackgroundTask()
        feedbackGenerator.impactOccurred()
    }
    
    private func startBackgroundTask() {
        // Завершаем предыдущую задачу, если она есть
        endBackgroundTask()
        
        // Создаем новую фоновую задачу
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "TimerTask") { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    private func saveAction(_ action: ProgressAction) {
        lastAction = action
        canUndo = true
    }
    
    private func updateProgress() {
        // Сначала проверяем валидность
        guard !currentValue.isNaN && !currentValue.isInfinite else {
            currentValue = 0
            progress = 0
            return
        }
        
        // Затем обновляем все значения
        let oldProgress = progress
        let newProgress = min(max(0, currentValue), habit.goal)
        
        // Проверяем, есть ли реальные изменения
        guard oldProgress != newProgress else { return }
        
        // Обновляем только если есть изменения
        progress = newProgress
        let wasCompleted = isCompleted
        isCompleted = currentValue >= habit.goal
        
        // Обрабатываем достижение цели
        if isCompleted {
            if isPlaying { pauseTimer() }
            if !wasCompleted { 
                handleGoalCompletion()
                notificationGenerator.notificationOccurred(.success)
            }
        }
        
        // Уведомляем об изменениях и сохраняем
        onUpdate?(currentValue)
        saveState()
    }
    
    private func handleGoalCompletion() {
        isCompleted = true
        if isPlaying { pauseTimer() }
        onComplete?()
    }
    
    private func loadState() {
        if let data = userDefaults.data(forKey: stateKey),
           let state = try? JSONDecoder().decode(HabitState.self, from: data),
           state.habitId == habit.id
        {
            // Проверяем, не начался ли новый день
            if Calendar.current.isDateInToday(state.lastUpdate) {
                currentValue = state.currentValue
                isCompleted = state.isCompleted
            } else {
                // Новый день - сбрасываем прогресс
                currentValue = 0
                isCompleted = false
                // Удаляем старое состояние
                userDefaults.removeObject(forKey: stateKey)
            }
        } else {
            currentValue = 0
            isCompleted = false
        }
        
        // Защита от некорректных значений при загрузке
        if currentValue.isNaN || currentValue.isInfinite || currentValue < 0 {
            currentValue = 0
        }
        
        updateProgress()
    }
    
    private func saveState() {
        let state = HabitState(
            habitId: habit.id,
            currentValue: currentValue,
            isCompleted: isCompleted,
            lastUpdate: Date()
        )
        
        if let data = try? JSONEncoder().encode(state) {
            userDefaults.set(data, forKey: stateKey)
        }
    }
    
    deinit {
        pauseTimer()
    }
} 