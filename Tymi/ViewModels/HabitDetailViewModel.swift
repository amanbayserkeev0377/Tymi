import SwiftUI
import Combine
import UIKit

final class HabitDetailViewModel: ObservableObject {
    private let habit: Habit
    private let dataStore: HabitDataStore
    private var timerManager: HabitTimerManaging
    private var actionManager: HabitActionManaging
    private var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var currentValue: ValueType
    @Published private(set) var isCompleted: Bool = false
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var bestStreak: Int = 0
    @Published private(set) var completedCount: Int = 0
    @Published var isPlaying: Bool = false
    @Published var showManualInput: Bool = false
    @Published var isAddMode: Bool = false
    @Published var canUndo: Bool = false
    
    private var wasRunningBeforeBackground = false
    private var startTime: Date?
    private var lastUpdate: Date = Date()
    private var lastAction: ProgressAction?
    private var totalAddedAmount: Double = 0
    private var undoneAmount: Double = 0
    private var statisticsCalculator: HabitStatisticsCalculating
    
    var onUpdate: ((Double) -> Void)?
    
    init(habit: Habit, dataStore: HabitDataStore = UserDefaultsService.shared) {
        self.habit = habit
        self.dataStore = dataStore
        self.currentValue = habit.type == .count ? .count(0) : .time(0)
        
        self.timerManager = HabitTimerManager(habit: habit, dataStore: dataStore)
        self.actionManager = HabitActionManager(habit: habit, dataStore: dataStore)
        self.statisticsCalculator = HabitStatisticsCalculator(habit: habit, dataStore: dataStore)
        
        setupTimerManager()
        setupNotifications()
        loadStatistics()
    }
    
    private func setupTimerManager() {
        timerManager.onValueUpdate = { [weak self] newValue in
            self?.currentValue = newValue
            self?.updateProgress()
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppDidEnterBackground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleAppWillEnterForeground()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func increment(by amount: Double = 1) {
        actionManager.increment(by: amount)
    }
    
    func decrement(by amount: Double = 1) {
        actionManager.decrement(by: amount)
    }
    
    func setValue(_ value: Double) {
        actionManager.setValue(value, isAddMode: isAddMode)
    }
    
    func reset() {
        actionManager.reset()
    }
    
    func toggleTimer() {
        if isCompleted {
            timerManager.pause()
            return
        }
        
        if isPlaying {
            timerManager.pause()
        } else {
            timerManager.start()
        }
    }
    
    func undo() {
        actionManager.undo()
    }
    
    func showManualInputPanel(isAdd: Bool = false) {
        isAddMode = isAdd
        showManualInput = true
    }
    
    // MARK: - App Lifecycle
    
    func handleAppDidEnterBackground() {
        wasRunningBeforeBackground = isPlaying
        if isPlaying {
            timerManager.pauseIfNeeded()
            saveFullState()
        }
    }
    
    func handleAppWillEnterForeground() {
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
                    timerManager.resumeIfNeeded()
                }
            }
        }
    }
    
    func onAppear() {
        loadStatistics()
    }
    
    func onDisappear() {
        timerManager.cleanup()
        saveFullState()
    }
    
    // MARK: - Private Methods
    
    private func updateProgress() {
        isCompleted = currentValue.doubleValue >= habit.goal.doubleValue
        isPlaying = timerManager.isPlaying
        canUndo = actionManager.canUndo
        
        let doubleValue: Double = currentValue.doubleValue
        onUpdate?(doubleValue)
    }
    
    private func loadState() {
        guard let data = UserDefaults.standard.data(forKey: "habit_state_\(habit.id.uuidString)"),
              let state = try? JSONDecoder().decode(HabitState.self, from: data)
        else { return }
        
        currentValue = state.currentValue
        isCompleted = state.isCompleted
        lastUpdate = state.lastUpdate
        isPlaying = state.isPlaying
        startTime = state.startTime
        lastAction = state.lastActionType.map { type in
            ProgressAction(
                oldValue: currentValue,
                newValue: currentValue,
                type: type,
                timestamp: state.lastActionTimestamp ?? Date(),
                addedAmount: state.lastActionAmount
            )
        }
        totalAddedAmount = state.totalAddedAmount
        undoneAmount = state.undoneAmount
    }
    
    private func saveState() {
        let state = HabitState(
            habitId: habit.id,
            currentValue: currentValue,
            isCompleted: isCompleted,
            lastUpdate: lastUpdate,
            isPlaying: isPlaying,
            startTime: startTime,
            habitType: habit.type,
            lastActionTimestamp: lastAction?.timestamp,
            lastActionType: lastAction?.type,
            lastActionAmount: lastAction?.addedAmount,
            totalAddedAmount: totalAddedAmount,
            undoneAmount: undoneAmount
        )
        
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: "habit_state_\(habit.id.uuidString)")
        }
    }
    
    private func saveFullState() {
        let state = HabitState(
            habitId: habit.id,
            currentValue: currentValue,
            isCompleted: isCompleted,
            lastUpdate: lastUpdate,
            isPlaying: isPlaying,
            startTime: startTime,
            habitType: habit.type,
            lastActionTimestamp: lastAction?.timestamp,
            lastActionType: lastAction?.type,
            lastActionAmount: lastAction?.addedAmount,
            totalAddedAmount: totalAddedAmount,
            undoneAmount: undoneAmount
        )
        
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: "habit_full_state_\(habit.id.uuidString)")
        }
    }
    
    private func loadFullState() -> HabitState? {
        guard let data = UserDefaults.standard.data(forKey: "habit_full_state_\(habit.id.uuidString)"),
              let state = try? JSONDecoder().decode(HabitState.self, from: data)
        else { return nil }
        
        currentValue = state.currentValue
        isCompleted = state.isCompleted
        lastUpdate = state.lastUpdate
        isPlaying = state.isPlaying
        startTime = state.startTime
        lastAction = state.lastActionType.map { type in
            ProgressAction(
                oldValue: currentValue,
                newValue: currentValue,
                type: type,
                timestamp: state.lastActionTimestamp ?? Date(),
                addedAmount: state.lastActionAmount
            )
        }
        totalAddedAmount = state.totalAddedAmount
        undoneAmount = state.undoneAmount
        
        return state
    }
    
    // MARK: - Statistics Methods
    
    func loadStatistics() {
        currentStreak = statisticsCalculator.currentStreak
        bestStreak = statisticsCalculator.bestStreak
        completedCount = statisticsCalculator.completedCount
    }
    
    deinit {
        timerManager.cleanup()
        NotificationCenter.default.removeObserver(self)
    }
}
