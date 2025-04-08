import SwiftUI
import Combine

class HabitDetailViewModel: ObservableObject {
    let habit: Habit
    private let habitStore: HabitStoreManager
    
    @Published var progress: Double = 0
    @Published var currentValue: Double = 0
    @Published var isCompleted: Bool = false
    @Published var isExpanded: Bool = false
    @Published var showManualInput: Bool = false
    @Published var isPlaying: Bool = false
    @Published var canUndo: Bool = false
    @Published var showOptions: Bool = false
    @Published var isAddMode: Bool = false
    
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
        let isPlaying: Bool
        let startTime: Date?
    }
    
    private var userDefaults: UserDefaults {
        UserDefaults.standard
    }
    
    private var stateKey: String {
        "habit_state_\(habit.id.uuidString)"
    }
    
    private var wasRunningBeforeBackground = false
    private var startTime: Date?
    
    init(habit: Habit, habitStore: HabitStoreManager) {
        self.habit = habit
        self.habitStore = habitStore
        loadState()
        feedbackGenerator.prepare()
        notificationGenerator.prepare()
        
        // Наблюдаем за жизненным циклом приложения
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
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
        if isAddMode {
            currentValue += value
        } else {
            currentValue = value
        }
        
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
    
    func showManualInputPanel(isAdd: Bool = false) {
        isAddMode = isAdd
        showManualInput = true
    }
    
    // MARK: - App Lifecycle
    
    @objc private func handleAppDidEnterBackground() {
        wasRunningBeforeBackground = isPlaying
        if isPlaying {
            pauseTimerIfNeeded()
            saveFullState()
        }
    }
    
    @objc private func handleAppWillEnterForeground() {
        if wasRunningBeforeBackground && !isCompleted {
            if let state = loadFullState() {
                currentValue = state.currentValue
                isCompleted = state.isCompleted
                isPlaying = state.isPlaying
                startTime = state.startTime
            }
            resumeTimerIfNeeded()
        }
    }
    
    func onAppear() {
        resumeTimerIfNeeded()
    }
    
    func onDisappear() {
        pauseTimerIfNeeded()
        saveFullState()
    }
    
    // MARK: - Timer Management
    private func resumeTimerIfNeeded() {
        guard habit.type == .time, !isCompleted else { return }
        
        if let savedState = loadFullState(), savedState.isPlaying {
            isPlaying = true
            startTime = Date()
            
            // Учитываем прошедшее время
            let elapsed = Date().timeIntervalSince(savedState.lastUpdate)
            if elapsed > 0 && elapsed < 3600 { // Ограничиваем максимум 1 часом
                currentValue += elapsed
                updateProgress()
            }
        } else {
            isPlaying = true
            startTime = Date()
        }
    }
    
    private func pauseTimerIfNeeded() {
        guard habit.type == .time else { return }
        isPlaying = false
        if let start = startTime {
            let elapsed = Date().timeIntervalSince(start)
            currentValue += elapsed
            startTime = nil
            updateProgress()
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
        
        // Сохраняем прогресс в HabitStore
        habitStore.saveProgress(
            for: habit,
            value: currentValue,
            isCompleted: isCompleted
        )
    }
    
    private func handleGoalCompletion() {
        isCompleted = true
        if isPlaying { pauseTimer() }
        onComplete?()
    }
    
    private func loadState() {
        if let state = loadFullState() {
            currentValue = state.currentValue
            isCompleted = state.isCompleted
            isPlaying = state.isPlaying
            startTime = state.startTime
            
            // Если таймер был запущен, учитываем прошедшее время
            if isPlaying {
                let elapsed = Date().timeIntervalSince(state.lastUpdate)
                if elapsed > 0 && elapsed < 3600 { // Ограничиваем максимум 1 часом
                    currentValue += elapsed
                }
            }
        } else if let progress = habitStore.getProgress(for: habit) {
            currentValue = progress.value
            isCompleted = progress.isCompleted
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
        habitStore.saveProgress(
            for: habit,
            value: currentValue,
            isCompleted: isCompleted
        )
    }
    
    private func saveFullState() {
        let state = HabitState(
            habitId: habit.id,
            currentValue: currentValue,
            isCompleted: isCompleted,
            lastUpdate: Date(),
            isPlaying: isPlaying,
            startTime: startTime
        )
        
        if let encoded = try? JSONEncoder().encode(state) {
            userDefaults.set(encoded, forKey: stateKey)
        }
    }
    
    private func loadFullState() -> HabitState? {
        guard let data = userDefaults.data(forKey: stateKey),
              let state = try? JSONDecoder().decode(HabitState.self, from: data),
              state.habitId == habit.id
        else {
            return nil
        }
        return state
    }
    
    deinit {
        pauseTimer()
    }
} 