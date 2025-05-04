import SwiftUI
import SwiftData

struct HabitDetailView: View {
    // MARK: - Properties
    let habit: Habit
    let date: Date
    
    @StateObject private var viewModel: HabitDetailViewModel
    @State private var isShowingEditSheet = false
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var habitsUpdateService: HabitsUpdateService
    
    // MARK: - Initialization
    init(habit: Habit, date: Date = .now) {
        self.habit = habit
        self.date = date
        
        _viewModel = StateObject(wrappedValue: HabitDetailViewModel(
            habit: habit,
            date: date,
            modelContext: ModelContext(ModelContainer.empty),
            habitsUpdateService: HabitsUpdateService()
        ))
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 20) {
            // Header with close and menu buttons
            HStack {
                
                Spacer()
                
                Text(habit.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Menu {
                    Button {
                        viewModel.isEditSheetPresented = true
                    } label: {
                        Label("edit".localized, systemImage: "pencil")
                    }
                    
                    Button {
                        viewModel.toggleFreeze()
                    } label: {
                        Label(habit.isFreezed ? "unfreeze".localized : "freeze".localized, systemImage: habit.isFreezed ? "flame" : "snowflake")
                    }
                    
                    Button(role: .destructive) {
                        viewModel.alertState.isDeleteAlertPresented = true
                    } label: {
                        Label("delete".localized, systemImage: "trash")
                    }
                    .tint(.red)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.gray.opacity(0.1) : Color.gray.opacity(0.1))
                        )
                }
                .modifier(HapticManager.shared.sensoryFeedback(.selection, trigger: true))
            }
            .padding(.top)
            
            // Goal header
            Text("goal".localized(with: viewModel.formattedGoal))
                .font(.subheadline)
                .padding(.bottom, 5)
            
            // Statistics section
            StatisticsSection(
                currentStreak: viewModel.currentStreak,
                bestStreak: viewModel.bestStreak,
                totalCompletions: viewModel.totalCompletions
            )
            
            // Progress controls
            ProgressControlSection(
                habit: habit,
                currentProgress: .constant(viewModel.currentProgress),
                completionPercentage: viewModel.completionPercentage,
                formattedProgress: viewModel.formattedProgress,
                onIncrement: viewModel.incrementProgress,
                onDecrement: viewModel.decrementProgress
            )
            
            // Action buttons
            ActionButtonsSection(
                habit: habit,
                isTimerRunning: viewModel.isTimerRunning,
                onReset: { viewModel.alertState.isResetAlertPresented = true },
                onTimerToggle: {
                    if habit.type == .time {
                        viewModel.toggleTimer()
                    } else {
                        viewModel.alertState.isCountAlertPresented = true
                    }
                },
                onManualEntry: {
                    viewModel.alertState.isTimeAlertPresented = true
                }
            )
            
            Spacer()
            
            // Complete button at the bottom
            Button(action: {
                viewModel.completeHabit()
            }) {
                Text(viewModel.isAlreadyCompleted ? "completed".localized : "complete".localized)
                    .font(.headline)
                    .foregroundStyle(
                        colorScheme == .dark ? .black : .white
                    )
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        viewModel.isAlreadyCompleted
                        ? Color.gray
                        : (colorScheme == .dark
                           ? Color.white.opacity(0.7)
                           : Color.black)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(viewModel.isAlreadyCompleted)
            .modifier(HapticManager.shared.sensoryFeedback(.impact(weight: .medium), trigger: !viewModel.isAlreadyCompleted))
            .padding(.horizontal)
            .padding(.bottom)
        }
        .onAppear {
            viewModel.modelContext = modelContext
            viewModel.habitsUpdateService = habitsUpdateService
        }
        
        .padding()
        
        .sheet(isPresented: $viewModel.isEditSheetPresented) {
            NewHabitView(habit: habit)
                .presentationBackground {
                    ZStack {
                        Rectangle().fill(.ultraThinMaterial)
                        if colorScheme != .dark {
                            Color.white.opacity(0.6)
                        }
                    }
                }
        }
        .habitDetailAlerts(
            habit: habit,
            date: date,
            timerService: viewModel.timerService,
            alertState: $viewModel.alertState,
            onReset: viewModel.resetProgress,
            onDelete: viewModel.deleteHabit
        )
        .freezeHabitAlert(isPresented: $viewModel.alertState.isFreezeAlertPresented) {
            viewModel.isEditSheetPresented = false
        }
        .onDisappear {
            viewModel.saveProgress()
        }
        .onChange(of: viewModel.alertState.successFeedbackTrigger) { _, newValue in
            if newValue {
                HapticManager.shared.play(.success)
            }
        }
        .onChange(of: viewModel.alertState.errorFeedbackTrigger) { _, newValue in
            if newValue {
                HapticManager.shared.play(.error)
            }
        }
    }
}

extension ModelContainer {
    static var empty: ModelContainer {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            return try ModelContainer(for: Habit.self, HabitCompletion.self, configurations: config)
        } catch {
            fatalError("Failed to create empty model container: \(error)")
        }
    }
}
