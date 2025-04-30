import SwiftUI
import SwiftData
import Combine

@MainActor
class HabitDetailViewModel: ObservableObject {
    // MARK: - Dependencies
    let habit: Habit
    let date: Date
    var modelContext: ModelContext
    var habitsUpdateService: HabitsUpdateService
    let timerService: HabitTimerService
    
    // MARK: - Published Properties
    @Published private(set) var currentProgress: Int = 0
    @Published private(set) var completionPercentage: Double = 0
    @Published private(set) var formattedProgress: String = ""
    @Published private(set) var isTimerRunning: Bool = false
    @Published var isEditSheetPresented = false
    
    // MARK: - Alert States
    @Published var isResetAlertPresented = false
    @Published var isCountAlertPresented = false
    @Published var isTimeAlertPresented = false
    @Published var isDeleteAlertPresented = false
    @Published var isFreezeAlertPresented = false
    
    // MARK: - Input States
    @Published var countInputText = ""
    @Published var hoursInputText = ""
    @Published var minutesInputText = ""
    
    // MARK: - Feedback States
    @Published var successFeedbackTrigger = false
    @Published var errorFeedbackTrigger = false
    
    // MARK: - Cancellables
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
        timerService: HabitTimerService = .shared,
        habitsUpdateService: HabitsUpdateService
    ) {
        self.habit = habit
        self.date = date
        self.modelContext = modelContext
        self.timerService = timerService
        self.habitsUpdateService = habitsUpdateService
        
        setupInitialState()
        setupSubscriptions()
    }
    
    // MARK: - Setup
    private func setupInitialState() {
        currentProgress = timerService.getCurrentProgress(for: habit.id)
        updateProgressMetrics()
        
        if habit.type == .time {
            timerService.restoreTimerState(for: habit.id)
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
        currentProgress = timerService.getCurrentProgress(for: habit.id)
        updateProgressMetrics()
        habitsUpdateService.triggerUpdate()
    }
    
    // MARK: - Timer Management
    func toggleTimer() {
        if timerService.isTimerRunning(for: habit.id) {
            timerService.stopTimer(for: habit.id)
        } else {
            timerService.startTimer(for: habit.id, initialProgress: currentProgress)
        }
        isTimerRunning = timerService.isTimerRunning(for: habit.id)
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
        isFreezeAlertPresented = true
        habitsUpdateService.triggerUpdate()
    }
    
    private func unfreezeHabit() {
        habit.isFreezed = false
        habitsUpdateService.triggerUpdate()
    }
    
    func deleteHabit() {
        modelContext.delete(habit)
        errorFeedbackTrigger.toggle()
    }
    
    // MARK: - Progress Actions
    func resetProgress() {
        timerService.resetTimer(for: habit.id)
        updateProgress()
    }
    
    func completeHabit() {
        timerService.addProgress(habit.goal - currentProgress, for: habit.id)
        saveProgress()
        successFeedbackTrigger.toggle()
    }
    
    func saveProgress() {
        let existingProgress = habit.progressForDate(date)
        let currentProgress = timerService.getCurrentProgress(for: habit.id)
        if currentProgress != existingProgress {
            habit.addProgress(currentProgress - existingProgress, for: date)
            habitsUpdateService.triggerUpdate()
        }
    }
    
    // MARK: - Input Handling
    func handleCountInput() {
        if let value = Int(countInputText), value > 0 {
            timerService.addProgress(value, for: habit.id)
            successFeedbackTrigger.toggle()
        }
        countInputText = ""
        updateProgress()
    }
    
    func handleTimeInput() {
        let minutes = Int(minutesInputText) ?? 0
        let hours = Int(hoursInputText) ?? 0
        let totalSeconds = (hours * 3600) + (minutes * 60)
        
        if totalSeconds > 0 {
            timerService.addProgress(totalSeconds, for: habit.id)
            successFeedbackTrigger.toggle()
        }
        
        minutesInputText = ""
        hoursInputText = ""
        updateProgress()
    }
} 