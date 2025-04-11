import SwiftUI
import Combine

enum ValueType {
    case count(Int32)
    case time(Double)
    
    var doubleValue: Double {
        switch self {
        case .count(let value): return Double(value)
        case .time(let value): return value
        }
    }
    
    static func fromDouble(_ value: Double, type: HabitType) -> ValueType {
        switch type {
        case .count: return .count(Int32(min(max(value, 0), Double(Int32.max))))
        case .time: return .time(max(value, 0))
        }
    }
}

class HabitDetailViewModel: ObservableObject {
    let habit: Habit
    private let habitStore: HabitStoreManager
    
    @Published var progress: ValueType
    @Published var currentValue: ValueType
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
        let oldValue: ValueType
        let newValue: ValueType
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
        let currentValue: ValueType
        let isCompleted: Bool
        let lastUpdate: Date
        let isPlaying: Bool
        let startTime: Date?
        let habitType: HabitType
        
        init(habitId: UUID, currentValue: ValueType, isCompleted: Bool, lastUpdate: Date, isPlaying: Bool, startTime: Date?, habitType: HabitType) {
            self.habitId = habitId
            self.currentValue = currentValue
            self.isCompleted = isCompleted
            self.lastUpdate = lastUpdate
            self.isPlaying = isPlaying
            self.startTime = startTime
            self.habitType = habitType
        }
        
        enum CodingKeys: String, CodingKey {
            case habitId, currentValue, isCompleted, lastUpdate, isPlaying, startTime, habitType
            case countValue, timeValue, type
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            habitId = try container.decode(UUID.self, forKey: .habitId)
            isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
            lastUpdate = try container.decode(Date.self, forKey: .lastUpdate)
            isPlaying = try container.decode(Bool.self, forKey: .isPlaying)
            startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
            habitType = try container.decode(HabitType.self, forKey: .habitType)
            
            // Проверяем, есть ли старый формат (Double)
            if let doubleValue = try? container.decode(Double.self, forKey: .currentValue) {
                currentValue = ValueType.fromDouble(doubleValue, type: habitType)
            } else {
                let type = try container.decode(String.self, forKey: .type)
                switch type {
                case "count":
                    let value = try container.decode(Int32.self, forKey: .countValue)
                    currentValue = .count(value)
                case "time":
                    let value = try container.decode(Double.self, forKey: .timeValue)
                    currentValue = .time(value)
                default:
                    throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid value type")
                }
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(habitId, forKey: .habitId)
            try container.encode(isCompleted, forKey: .isCompleted)
            try container.encode(lastUpdate, forKey: .lastUpdate)
            try container.encode(isPlaying, forKey: .isPlaying)
            try container.encodeIfPresent(startTime, forKey: .startTime)
            try container.encode(habitType, forKey: .habitType)
            
            switch currentValue {
            case .count(let value):
                try container.encode("count", forKey: .type)
                try container.encode(value, forKey: .countValue)
            case .time(let value):
                try container.encode("time", forKey: .type)
                try container.encode(value, forKey: .timeValue)
            }
        }
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
        self.currentValue = habit.type == .count ? .count(0) : .time(0)
        self.progress = habit.type == .count ? .count(0) : .time(0)
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
        let newDoubleValue = currentValue.doubleValue + increment
        guard !newDoubleValue.isInfinite && !newDoubleValue.isNaN else { return }
        
        currentValue = ValueType.fromDouble(newDoubleValue, type: habit.type)
        
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
        let newDoubleValue = max(0, currentValue.doubleValue - decrement)
        currentValue = ValueType.fromDouble(newDoubleValue, type: habit.type)
        
        if oldValue.doubleValue != currentValue.doubleValue {
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
            let newDoubleValue = currentValue.doubleValue + value
            currentValue = ValueType.fromDouble(newDoubleValue, type: habit.type)
        } else {
            currentValue = ValueType.fromDouble(value, type: habit.type)
        }
        
        if oldValue.doubleValue != currentValue.doubleValue {
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
        currentValue = habit.type == .count ? .count(0) : .time(0)
        
        if oldValue.doubleValue != 0 {
            notificationGenerator.notificationOccurred(.warning)
        }
        
        saveAction(
            .init(
                oldValue: oldValue,
                newValue: currentValue,
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
                
                // Если таймер был запущен, учитываем прошедшее время
                if isPlaying {
                    let elapsed = Date().timeIntervalSince(state.lastUpdate)
                    if elapsed > 0 && elapsed < 3600 { // Ограничиваем максимум 1 часом
                        switch currentValue {
                        case .time(let value):
                            let newValue = value + elapsed
                            currentValue = .time(newValue)
                        default:
                            break
                        }
                        updateProgress()
                    }
                    resumeTimerIfNeeded()
                }
            }
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
                switch currentValue {
                case .time(let value):
                    let newValue = value + elapsed
                    currentValue = .time(newValue)
                default:
                    break
                }
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
            currentValue = ValueType.fromDouble(currentValue.doubleValue + elapsed, type: habit.type)
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
            let newValue = self.currentValue.doubleValue + cappedTimeDiff
            
            // Защита от переполнения
            guard newValue.isFinite && !newValue.isNaN else {
                self.pauseTimer()
                return
            }
            
            let oldValue = self.currentValue
            self.currentValue = ValueType.fromDouble(newValue, type: self.habit.type)
            self.lastTimerUpdate = now
            
            // Обновляем только при реальных изменениях
            if oldValue.doubleValue != newValue {
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
        progress = ValueType.fromDouble(
            min(currentValue.doubleValue, habit.goal.doubleValue),
            type: habit.type
        )
        
        let isNowCompleted = currentValue.doubleValue >= habit.goal.doubleValue
        if isNowCompleted != isCompleted {
            isCompleted = isNowCompleted
            if isCompleted {
                notificationGenerator.notificationOccurred(.success)
                onComplete?()
            }
        }
        
        let doubleValue: Double = currentValue.doubleValue
        onUpdate?(doubleValue)
    }
    
    private func loadState() {
        guard let data = userDefaults.data(forKey: stateKey),
              let state = try? JSONDecoder().decode(HabitState.self, from: data),
              state.habitId == habit.id
        else {
            return
        }
        
        currentValue = state.currentValue
        isCompleted = state.isCompleted
        isPlaying = state.isPlaying
        startTime = state.startTime
        
        updateProgress()
    }
    
    private func saveState() {
        let state = HabitState(
            habitId: habit.id,
            currentValue: currentValue,
            isCompleted: isCompleted,
            lastUpdate: Date(),
            isPlaying: isPlaying,
            startTime: startTime,
            habitType: habit.type
        )
        
        if let data = try? JSONEncoder().encode(state) {
            userDefaults.set(data, forKey: stateKey)
        }
    }
    
    private func saveFullState() {
        let state = HabitState(
            habitId: habit.id,
            currentValue: currentValue,
            isCompleted: isCompleted,
            lastUpdate: Date(),
            isPlaying: isPlaying,
            startTime: startTime,
            habitType: habit.type
        )
        
        if let data = try? JSONEncoder().encode(state) {
            userDefaults.set(data, forKey: stateKey)
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
