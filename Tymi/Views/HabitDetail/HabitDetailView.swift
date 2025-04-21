import SwiftUI
import SwiftData

struct HabitDetailView: View {
    // MARK: - Properties
    let habit: Habit
    let date: Date
    
    @StateObject private var timerManager: HabitTimerManager
    @State private var hourglassRotation: Double = 0
    
    // State for input dialogs
    @State private var isCountAlertPresented = false
    @State private var countInputText = ""
    
    // State for TimePicker
    @State private var selectedHours = 0
    @State private var selectedMinutes = 0
    @State private var isTimePickerPresented = false
    
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
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    goalHeader
                    
                    Spacer(minLength: 20)
                    
                    // Progress controls
                    ProgressControlSection(
                        habit: habit,
                        currentProgress: $timerManager.currentProgress,
                        completionPercentage: completionPercentage,
                        formattedProgress: formattedProgress,
                        onIncrement: incrementProgress,
                        onDecrement: decrementProgress
                    )
                    
                    Spacer(minLength: 20)
                    
                    // Action buttons
                    ActionButtonsSection(
                        habit: habit,
                        isTimerRunning: timerManager.isRunning,
                        hourglassRotation: hourglassRotation,
                        onReset: resetProgress,
                        onTimerToggle: {
                            if habit.type == .time {
                                toggleTimer()
                            } else {
                                isCountAlertPresented = true
                            }
                        },
                        onManualEntry: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                hourglassRotation += 360
                                isTimePickerPresented = true
                            }
                        }
                    )
                    
                    Spacer()
                    
                    completeButton
                }
                .padding()
            }
            .navigationTitle(habit.title)
            .navigationBarTitleDisplayMode(.inline)
            
            // Alert for Count type
            .alert("Enter value", isPresented: $isCountAlertPresented) {
                TextField("Value", text: $countInputText)
                    .keyboardType(.numberPad)
                Button("Cancel", role: .cancel) {
                    countInputText = ""
                }
                Button("Add") {
                    if let value = Int(countInputText), value > 0 {
                        timerManager.addProgress(value)
                    }
                    countInputText = ""
                }
            }
            .tint(.primary)
            
            // Overlay for Time Picker with Blur
            .overlay {
                if isTimePickerPresented {                    
                    WheelPickerView(
                        hours: $selectedHours,
                        minutes: $selectedMinutes,
                        isPresented: $isTimePickerPresented
                    ) { totalSeconds in
                        timerManager.addProgress(totalSeconds)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            hourglassRotation += 360
                        }
                    }
                    .frame(width: 280, height: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 10)
                    )
                    .scaleEffect(isTimePickerPresented ? 1 : 0.8)
                    .opacity(isTimePickerPresented ? 1 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTimePickerPresented)
                    .padding(.bottom, 20)
                }
            }
        }
        .onDisappear {
            saveProgress()
        }
    }
    
    // MARK: - Subviews
    
    private var goalHeader: some View {
        Text("Goal: \(habit.formattedGoal)")
            .font(.subheadline)
            .padding(.top)
    }
    
    private var completeButton: some View {
        Button(action: {
            saveProgress()
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
        .padding(.bottom, 16)
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
}
