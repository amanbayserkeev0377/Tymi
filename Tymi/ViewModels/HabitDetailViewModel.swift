import SwiftUI
import Combine
import UIKit

final class HabitDetailViewModel: ObservableObject {
    let habit: Habit
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
    @Published var selectedDate: Date = Date()
    @Published var showingCalendar: Bool = false
    @Published var isHistoricalView: Bool = false
    
    private var wasRunningBeforeBackground = false
    private var startTime: Date?
    private var lastUpdate: Date = Date()
    private var lastAction: ProgressAction?
    private var totalAddedAmount: Double = 0
    private var undoneAmount: Double = 0
    private var statisticsCalculator: HabitStatisticsCalculating
    
    var onUpdate: ((Double) -> Void)?
    
    var progress: ValueType {
        ValueType.fromDouble(
            min(currentValue.doubleValue, habit.goal.doubleValue),
            type: habit.type
        )
    }
    
    var formattedSelectedDate: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let selectedDay = calendar.startOfDay(for: selectedDate)
        
        if calendar.isDate(selectedDay, inSameDayAs: today) {
            return "Сегодня"
        } else if calendar.isDate(selectedDay, inSameDayAs: yesterday) {
            return "Вчера"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMMM"
            formatter.locale = Locale(identifier: "ru_RU")
            return formatter.string(from: selectedDate)
        }
    }
    
    init(habit: Habit, dataStore: HabitDataStore = UserDefaultsService.shared) {
        self.habit = habit
        self.dataStore = dataStore
        self.currentValue = habit.type == .count ? .count(0) : .time(0)
        
        self.timerManager = HabitTimerManager(habit: habit, dataStore: dataStore)
        self.actionManager = HabitActionManager(habit: habit, dataStore: dataStore)
        self.statisticsCalculator = HabitStatisticsCalculator(habit: habit, dataStore: dataStore)
        
        setupTimerManager()
        setupActionManager()
        setupNotifications()
        loadStatistics()
    }
    
    private func setupTimerManager() {
        timerManager.onValueUpdate = { [weak self] newValue in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.currentValue = newValue
                self.updateProgress()
            }
        }
    }
    
    private func setupActionManager() {
        actionManager.onValueUpdate = { [weak self] newValue in
            guard let self = self else { return }
            self.currentValue = newValue
            self.updateProgress()
        }
        
        actionManager.onCompletion = { [weak self] in
            guard let self = self else { return }
            self.isCompleted = true
            self.updateProgress()
        }
        
        self.currentValue = actionManager.currentValue
        self.canUndo = actionManager.canUndo
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
        canUndo = actionManager.canUndo
    }
    
    func decrement(by amount: Double = 1) {
        actionManager.decrement(by: amount)
        canUndo = actionManager.canUndo
    }
    
    func setValue(_ value: Double) {
        actionManager.setValue(value, isAddMode: isAddMode)
        canUndo = actionManager.canUndo
    }
    
    func reset() {
        actionManager.reset()
        canUndo = actionManager.canUndo
    }
    
    func toggleTimer() {
        if isCompleted {
            timerManager.pause()
            isPlaying = false
            return
        }
        
        if currentValue.doubleValue >= habit.goal.doubleValue {
            isCompleted = true
            timerManager.pause()
            isPlaying = false
            return
        }
        
        if isPlaying {
            timerManager.pause()
            isPlaying = false
        } else {
            timerManager.start()
            isPlaying = true
        }
        
        updateProgress()
    }
    
    func undo() {
        actionManager.undo()
        canUndo = actionManager.canUndo
    }
    
    func showManualInputPanel(isAdd: Bool = false) {
        isAddMode = isAdd
        showManualInput = true
    }
    
    func loadProgressForDate(_ date: Date) {
        selectedDate = date
        isHistoricalView = !Calendar.current.isDateInToday(date)
        
        // Загружаем прогресс за выбранную дату
        if let progress = dataStore.getProgress(for: habit.id, on: date) {
            currentValue = ValueType.fromDouble(progress.value, type: habit.type)
            isCompleted = progress.value >= habit.goal.doubleValue
            canUndo = false // В историческом просмотре отключим отмену действий
        } else {
            // Если прогресса нет, сбрасываем значения
            currentValue = habit.type == .count ? .count(0) : .time(0)
            isCompleted = false
            canUndo = false
        }
        
        updateProgress()
    }
    
    func returnToToday() {
        loadProgressForDate(Date())
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
        
        currentValue = actionManager.currentValue
        canUndo = actionManager.canUndo
        
        updateProgress()
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
