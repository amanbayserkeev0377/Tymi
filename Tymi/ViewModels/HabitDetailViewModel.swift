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
    @Published var showManualInput: Bool = false
    @Published var isPlaying: Bool = false
    @Published var canUndo: Bool = false
    @Published var showOptions: Bool = false
    @Published var isAddMode: Bool = false
    @Published private var originalAction: ProgressAction? = nil
    @Published private var totalAddedAmount: Double = 0
    @Published private var undoneAmount: Double = 0
    
    var onUpdate: ((Double) -> Void)?
    var onComplete: (() -> Void)?
    
    private struct ProgressAction {
        let oldValue: ValueType
        let newValue: ValueType
        let type: ActionType
        let timestamp: Date
        let addedAmount: Double?
        
        init(oldValue: ValueType, newValue: ValueType, type: ActionType, timestamp: Date, addedAmount: Double? = nil) {
            self.oldValue = oldValue
            self.newValue = newValue
            self.type = type
            self.timestamp = timestamp
            self.addedAmount = addedAmount
        }
        
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
        let lastActionTimestamp: Date?
        let lastActionType: String?
        let lastActionAmount: Double?
        let totalAddedAmount: Double
        let undoneAmount: Double
        
        init(habitId: UUID, currentValue: ValueType, isCompleted: Bool, lastUpdate: Date, isPlaying: Bool, startTime: Date?, habitType: HabitType, lastActionTimestamp: Date? = nil, lastActionType: String? = nil, lastActionAmount: Double? = nil, totalAddedAmount: Double = 0, undoneAmount: Double = 0) {
            self.habitId = habitId
            self.currentValue = currentValue
            self.isCompleted = isCompleted
            self.lastUpdate = lastUpdate
            self.isPlaying = isPlaying
            self.startTime = startTime
            self.habitType = habitType
            self.lastActionTimestamp = lastActionTimestamp
            self.lastActionType = lastActionType
            self.lastActionAmount = lastActionAmount
            self.totalAddedAmount = totalAddedAmount
            self.undoneAmount = undoneAmount
        }
        
        enum CodingKeys: String, CodingKey {
            case habitId, currentValue, isCompleted, lastUpdate, isPlaying, startTime, habitType
            case countValue, timeValue, type
            case lastActionTimestamp, lastActionType, lastActionAmount, totalAddedAmount, undoneAmount
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            habitId = try container.decode(UUID.self, forKey: .habitId)
            isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
            lastUpdate = try container.decode(Date.self, forKey: .lastUpdate)
            isPlaying = try container.decode(Bool.self, forKey: .isPlaying)
            startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
            habitType = try container.decode(HabitType.self, forKey: .habitType)
            
            lastActionTimestamp = try container.decodeIfPresent(Date.self, forKey: .lastActionTimestamp)
            lastActionType = try container.decodeIfPresent(String.self, forKey: .lastActionType)
            lastActionAmount = try container.decodeIfPresent(Double.self, forKey: .lastActionAmount)
            totalAddedAmount = try container.decode(Double.self, forKey: .totalAddedAmount)
            undoneAmount = try container.decode(Double.self, forKey: .undoneAmount)
            
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
            
            try container.encodeIfPresent(lastActionTimestamp, forKey: .lastActionTimestamp)
            try container.encodeIfPresent(lastActionType, forKey: .lastActionType)
            try container.encodeIfPresent(lastActionAmount, forKey: .lastActionAmount)
            try container.encode(totalAddedAmount, forKey: .totalAddedAmount)
            try container.encode(undoneAmount, forKey: .undoneAmount)
            
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
        
        let newDoubleValue = currentValue.doubleValue + increment
        guard !newDoubleValue.isInfinite && !newDoubleValue.isNaN else { return }
        
        currentValue = ValueType.fromDouble(newDoubleValue, type: habit.type)
        
        saveAction(
            .init(
                oldValue: oldValue,
                newValue: currentValue,
                type: .increment(amount: amount),
                timestamp: Date(),
                addedAmount: increment
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
        
        let addedAmount = isAddMode ? value : value - oldValue.doubleValue
        saveAction(
            .init(
                oldValue: oldValue,
                newValue: currentValue,
                type: .manualInput,
                timestamp: Date(),
                addedAmount: addedAmount
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
                timestamp: Date(),
                addedAmount: nil
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
        print("Отладка undo - originalAction: \(originalAction != nil), totalAddedAmount: \(totalAddedAmount), undoneAmount: \(undoneAmount)")
        
        guard let action = originalAction,
              Date().timeIntervalSince(action.timestamp) <= maxUndoTimeInterval,
              let actionAmount = action.addedAmount,
              actionAmount > 0,
              currentValue.doubleValue > 0
        else {
            canUndo = false
            return
        }
        
        let amountToSubtract: Double
        
        if case .increment(let incAmount) = action.type, incAmount == 1, totalAddedAmount > 1 {
            amountToSubtract = totalAddedAmount
            canUndo = false
            lastAction = nil
            originalAction = nil
            totalAddedAmount = 0
            undoneAmount = 0
        } else {
            amountToSubtract = min(actionAmount, currentValue.doubleValue)
            undoneAmount += 1
            
            if currentValue.doubleValue <= amountToSubtract {
                canUndo = false
                lastAction = nil
                originalAction = nil
                totalAddedAmount = 0
                undoneAmount = 0
            }
        }
        
        let newDoubleValue = max(0, currentValue.doubleValue - amountToSubtract)
        currentValue = ValueType.fromDouble(newDoubleValue, type: habit.type)
        
        print("Отладка undo - amountToSubtract: \(amountToSubtract), currentValue: \(currentValue.doubleValue)")
        
        feedbackGenerator.impactOccurred()
        updateProgress()
        saveState()
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
                
                if isPlaying {
                    let elapsed = Date().timeIntervalSince(state.lastUpdate)
                    if elapsed > 0 && elapsed < 3600 {
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
            
            let elapsed = Date().timeIntervalSince(savedState.lastUpdate)
            if elapsed > 0 && elapsed < 3600 {
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
            
            let timeDiff = now.timeIntervalSince(last)
            if timeDiff > 60 {
                self.lastTimerUpdate = now
                return
            }
            
            let cappedTimeDiff = min(timeDiff, 1.0)
            let newValue = self.currentValue.doubleValue + cappedTimeDiff
            
            guard newValue.isFinite && !newValue.isNaN else {
                self.pauseTimer()
                return
            }
            
            let oldValue = self.currentValue
            self.currentValue = ValueType.fromDouble(newValue, type: self.habit.type)
            self.lastTimerUpdate = now
            
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
        endBackgroundTask()
        
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
        originalAction = action
        
        if let amount = action.addedAmount, amount > 0 {
            if case .increment(let incAmount) = action.type, incAmount == 1 {
                totalAddedAmount += amount
            } else {
                totalAddedAmount = amount
            }
            undoneAmount = 0
        }
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
        
        totalAddedAmount = state.totalAddedAmount
        undoneAmount = state.undoneAmount
        
        if let timestamp = state.lastActionTimestamp, 
           let actionType = state.lastActionType,
           let amount = state.lastActionAmount {
            
            let type: ProgressAction.ActionType
            switch actionType {
            case "increment": type = .increment(amount: amount)
            case "manualInput": type = .manualInput
            case "reset": type = .reset
            default: type = .reset
            }
            
            originalAction = ProgressAction(
                oldValue: currentValue,
                newValue: currentValue,
                type: type,
                timestamp: timestamp,
                addedAmount: amount
            )
            
            canUndo = totalAddedAmount > undoneAmount
        }
        
        updateProgress()
    }
    
    private func saveState() {
        let actionType: String?
        switch originalAction?.type {
        case .increment: actionType = "increment"
        case .manualInput: actionType = "manualInput" 
        case .reset: actionType = "reset"
        case .none: actionType = nil
        }

        let state = HabitState(
            habitId: habit.id,
            currentValue: currentValue,
            isCompleted: isCompleted,
            lastUpdate: Date(),
            isPlaying: isPlaying,
            startTime: startTime,
            habitType: habit.type,
            lastActionTimestamp: originalAction?.timestamp,
            lastActionType: actionType,
            lastActionAmount: originalAction?.addedAmount,
            totalAddedAmount: totalAddedAmount,
            undoneAmount: undoneAmount
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
            habitType: habit.type,
            lastActionTimestamp: originalAction?.timestamp,
            lastActionType: {
                switch originalAction?.type {
                case .increment: return "increment"
                case .manualInput: return "manualInput" 
                case .reset: return "reset"
                case .none: return nil
                }
            }(),
            lastActionAmount: originalAction?.addedAmount,
            totalAddedAmount: totalAddedAmount,
            undoneAmount: undoneAmount
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
