import SwiftUI
import SwiftData

struct HabitDetailView: View {
    // MARK: - Properties
    let habit: Habit
    let date: Date
    
    @StateObject private var timerManager: HabitTimerManager
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
    
    // MARK: - Initialization
    init(habit: Habit, date: Date = .now) {
        self.habit = habit
        self.date = date
        self._timerManager = StateObject(wrappedValue: HabitTimerManager(initialProgress: habit.progressForDate(date)))
    }
    
    // MARK: - Computed Properties
    private var completionPercentage: Double {
        guard habit.goal > 0 else { return 0 }
        return min(Double(timerManager.currentProgress) / Double(habit.goal), 1.0)
    }
    
    private var formattedProgress: String {
        if habit.type == .count {
            return timerManager.currentProgress.formattedAsProgress(total: habit.goal)
        } else {
            return timerManager.currentProgress.formattedAsTime()
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 20) {
            // Header with habit title
            HStack {
                Spacer()
                
                Text(habit.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Menu {
                    Button(action: {
                        isShowingEditSheet = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: {
                        isDeleteAlertPresented = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .tint(.red)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
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
                currentProgress: $timerManager.currentProgress,
                completionPercentage: completionPercentage,
                formattedProgress: formattedProgress,
                onIncrement: incrementProgress,
                onDecrement: decrementProgress
            )
            
            // Action buttons
            ActionButtonsSection(
                habit: habit,
                isTimerRunning: timerManager.isRunning,
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
        
        // Reset confirmation alert
        .alert("Reset Progress", isPresented: $isResetAlertPresented) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                errorFeedbackTrigger.toggle()
                resetProgress()
            }
        } message: {
            Text("Do you want to reset your progress for today?")
        }
        
        // Delete confirmation alert
        .alert("Delete this habit? This can't be undone.", isPresented: $isDeleteAlertPresented) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteHabit()
            }
        }
        
        // Alert for Count type
        .alert("Add count", isPresented: $isCountAlertPresented) {
            TextField("", text: $countInputText)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) {
                countInputText = ""
            }
            Button("Add") {
                if let value = Int(countInputText), value > 0 {
                    timerManager.addProgress(value)
                    successFeedbackTrigger.toggle()
                }
                countInputText = ""
            }
        }
        .tint(.primary)
        
        // Alert for Time type
        .alert("Add time", isPresented: $isTimeAlertPresented) {
            TextField("minutes", text: $minutesInputText)
                .keyboardType(.numberPad)
            TextField("hours", text: $hoursInputText)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) {
                hoursInputText = ""
                minutesInputText = ""
            }
            Button("Add") {
                let minutes = Int(minutesInputText) ?? 0
                let hours = Int(hoursInputText) ?? 0
                
                // Convert to seconds and add to progress
                let totalSeconds = (hours * 3600) + (minutes * 60)
                if totalSeconds > 0 {
                    timerManager.addProgress(totalSeconds)
                    successFeedbackTrigger.toggle()
                }
                
                // Clear input fields
                minutesInputText = ""
                hoursInputText = ""
            }
        }
        .tint(.primary)
        .onDisappear {
            saveProgress()
        }
    }
    
    // MARK: - Subviews
    
    private var goalHeader: some View {
        Text("Goal: \(habit.formattedGoal)")
            .font(.subheadline)
    }
    
    private var completeButton: some View {
        Button(action: {
            saveProgress()
            successFeedbackTrigger.toggle()
            dismiss()
        }) {
            Text("Complete")
                .font(.headline)
                .foregroundStyle(
                    colorScheme == .dark ? .black : .white
                )
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal)
    }
    
    // MARK: - Methods
    
    private func saveProgress() {
        let existingProgress = habit.progressForDate(date)
        if timerManager.currentProgress != existingProgress {
            habit.addProgress(timerManager.currentProgress - existingProgress, for: date)
        }
    }
    
    private func incrementProgress() {
        if habit.type == .count {
            timerManager.addProgress(1)
        } else {
            timerManager.addProgress(60)
        }
    }
    
    private func decrementProgress() {
        if habit.type == .count {
            if timerManager.currentProgress > 0 {
                timerManager.addProgress(-1)
            }
        } else {
            if timerManager.currentProgress >= 60 {
                timerManager.addProgress(-60)
            } else {
                timerManager.resetTimer()
            }
        }
    }
    
    private func resetProgress() {
        timerManager.resetTimer()
    }
    
    private func toggleTimer() {
        if timerManager.isRunning {
            timerManager.stopTimer()
        } else {
            timerManager.startTimer()
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
