import SwiftUI
import SwiftData

struct HabitDetailView: View {
    // MARK: - Properties
    let habit: Habit
    let date: Date
    
    @StateObject private var timerService = HabitTimerService.shared
    @State private var isShowingEditSheet = false
    
    // State for alerts
    @State private var isResetAlertPresented = false
    @State private var isCountAlertPresented = false
    @State private var isTimeAlertPresented = false
    @State private var isDeleteAlertPresented = false
    
    // Input text state
    @State private var countInputText = ""
    @State private var hoursInputText = ""
    @State private var minutesInputText = ""
    
    // State for sensory feedback
    @State private var successFeedbackTrigger = false
    @State private var errorFeedbackTrigger = false
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var habitsUpdateService: HabitsUpdateService
    
    // MARK: - Initialization
    init(habit: Habit, date: Date = .now) {
        self.habit = habit
        self.date = date
    }
    
    // MARK: - Computed Properties
    private var completionPercentage: Double {
        guard habit.goal > 0 else { return 0 }
        return Double(timerService.getTotalProgress(for: habit.id)) / Double(habit.goal)
    }
    
    private var formattedProgress: String {
        if habit.type == .count {
            return timerService.getTotalProgress(for: habit.id).formattedAsProgress(total: habit.goal)
        } else {
            return timerService.getTotalProgress(for: habit.id).formattedAsTime()
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 24) {
            // Header with close and menu buttons
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                Menu {
                    Button(action: { isShowingEditSheet = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    if habit.isFreezed {
                        Button(action: { habit.isFreezed = false }) {
                            Label("Unfreeze", systemImage: "flame")
                        }
                        .tint(.orange)
                    } else {
                        Button(action: { habit.isFreezed = true }) {
                            Label("Freeze", systemImage: "snowflake")
                        }
                        .tint(.blue)
                    }
                    
                    Button(role: .destructive, action: { isDeleteAlertPresented = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(.primary)
                }
            }
            .padding(.top)
            
            // Goal header
            goalHeader
                .padding(.bottom, 5)
            
            // Progress controls
            ProgressControlSection(
                habit: habit,
                currentProgress: .constant(timerService.getCurrentProgress(for: habit.id)),
                completionPercentage: completionPercentage,
                formattedProgress: formattedProgress,
                onIncrement: incrementProgress,
                onDecrement: decrementProgress
            )
            
            // Action buttons
            ActionButtonsSection(
                habit: habit,
                isTimerRunning: timerService.isTimerRunning(for: habit.id),
                onReset: { isResetAlertPresented = true },
                onTimerToggle: {
                    if habit.type == .time {
                        toggleTimer()
                    } else {
                        isCountAlertPresented = true
                    }
                },
                onManualEntry: {
                    isTimeAlertPresented = true
                }
            )
            
            Spacer()
            
            // Complete button at the bottom
            completeButton
                .padding(.bottom)
        }
        .padding(.horizontal)
        .navigationBarHidden(true)
        .sensoryFeedback(.success, trigger: successFeedbackTrigger)
        .sensoryFeedback(.error, trigger: errorFeedbackTrigger)
        .sheet(isPresented: $isShowingEditSheet) {
            NewHabitView(habit: habit)
        }
        .modifier(HabitDetailAlerts(
            habit: habit,
            date: date,
            timerService: timerService,
            isResetAlertPresented: $isResetAlertPresented,
            isCountAlertPresented: $isCountAlertPresented,
            isTimeAlertPresented: $isTimeAlertPresented,
            isDeleteAlertPresented: $isDeleteAlertPresented,
            countInputText: $countInputText,
            hoursInputText: $hoursInputText,
            minutesInputText: $minutesInputText,
            successFeedbackTrigger: $successFeedbackTrigger,
            errorFeedbackTrigger: $errorFeedbackTrigger,
            onReset: resetProgress,
            onDelete: deleteHabit
        ))
        .onAppear {
            if habit.type == .time {
                timerService.restoreTimerState(for: habit.id)
            }
        }
        .onDisappear {
            saveProgress()
        }
    }
    
    // MARK: - Subviews
    
    private var completeButton: some View {
        Button(action: {
            completeHabit()
        }) {
            Text(isAlreadyCompleted ? "Completed" : "Complete")
                .font(.headline)
                .foregroundStyle(
                    colorScheme == .dark ? .black : .white
                )
                .frame(maxWidth: .infinity)
                .padding()
                .background(isAlreadyCompleted ? Color.gray.opacity(0.2) : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isAlreadyCompleted)
        .padding(.horizontal)
    }
    
    private var goalHeader: some View {
        Text("Goal: \(habit.formattedGoal)")
            .font(.subheadline)
    }
    
    // MARK: - Methods
    
    private var isAlreadyCompleted: Bool {
        return timerService.getCurrentProgress(for: habit.id) >= habit.goal
    }
    
    private func completeHabit() {
        withAnimation(.easeInOut(duration: 0.3)) {
            timerService.addProgress(habit.goal - timerService.getCurrentProgress(for: habit.id), for: habit.id)
        }

        saveProgress()
        habitsUpdateService.triggerUpdate()
        successFeedbackTrigger.toggle()
    }
    
    private func saveProgress() {
        let existingProgress = habit.progressForDate(date)
        let currentProgress = timerService.getCurrentProgress(for: habit.id)
        if currentProgress != existingProgress {
            habit.addProgress(currentProgress - existingProgress, for: date)
            habitsUpdateService.triggerUpdate()
        }
    }
    
    private func incrementProgress() {
        if habit.type == .count {
            timerService.addProgress(1, for: habit.id)
        } else {
            if timerService.isTimerRunning(for: habit.id) {
                timerService.stopTimer(for: habit.id)
            }
            timerService.addProgress(60, for: habit.id)
        }
        habitsUpdateService.triggerUpdate()
    }
    
    private func decrementProgress() {
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
        habitsUpdateService.triggerUpdate()
    }
    
    private func resetProgress() {
        timerService.resetTimer(for: habit.id)
        habitsUpdateService.triggerUpdate()
    }
    
    private func toggleTimer() {
        if timerService.isTimerRunning(for: habit.id) {
            timerService.stopTimer(for: habit.id)
        } else {
            timerService.startTimer(for: habit.id, initialProgress: timerService.getCurrentProgress(for: habit.id))
        }
    }
    
    private func deleteHabit() {
        modelContext.delete(habit)
        
        errorFeedbackTrigger.toggle()
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitCompletion.self, configurations: config)
    
    // Create test Count habit
    let countHabit = Habit(title: "Push-ups", type: .count, goal: 50)
    
    // Create test Time habit
    let timeHabit = Habit(title: "Meditation", type: .time, goal: 3600) // 1 hour
    
    return TabView {
        HabitDetailView(habit: countHabit)
            .tabItem {
                Label("Count", systemImage: "number")
            }
        
        HabitDetailView(habit: timeHabit)
            .tabItem {
                Label("Time", systemImage: "timer")
            }
    }
    .modelContainer(container)
}
