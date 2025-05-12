import SwiftUI
import SwiftData

struct HabitDetailView: View {
    // MARK: - Properties
    let habit: Habit
    let date: Date
    var onDelete: (() -> Void)?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    
    // MARK: - State Properties
    @State private var viewModel: HabitDetailViewModel?
    @State private var isContentReady = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            if let viewModel = viewModel, isContentReady {
                VStack(spacing: 15) {
                    // Header with title and menu
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
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                        .modifier(HapticManager.shared.sensoryFeedback(.selection, trigger: true))
                    }
                    .padding(.top)
                    // Goal header
                    Text("goal".localized(with: viewModel.formattedGoal))
                        .font(.subheadline)
                    
                    // Progress controls
                    ProgressControlSection(
                        habit: habit,
                        currentProgress: .constant(viewModel.currentProgress),
                        completionPercentage: viewModel.completionPercentage,
                        formattedProgress: viewModel.formattedProgress,
                        onIncrement: viewModel.incrementProgress,
                        onDecrement: viewModel.decrementProgress
                    )
                    
                    // Action buttons - одинаковые для всех дат
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
                .padding()
                // РЕШЕНИЕ: Используем явные байндинги
                .sheet(isPresented: Binding<Bool>(
                    get: { viewModel.isEditSheetPresented },
                    set: { viewModel.isEditSheetPresented = $0 }
                )) {
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
                .habitAlerts(
                    // РЕШЕНИЕ: Создаем явные байндинги для свойств viewModel
                    alertState: Binding<AlertState>(
                        get: { viewModel.alertState },
                        set: { viewModel.alertState = $0 }
                    ),
                    habit: habit,
                    progressService: viewModel.progressService,
                    onReset: {
                        viewModel.resetProgress()
                        viewModel.alertState.isResetAlertPresented = false
                    },
                    onDelete: {
                        viewModel.deleteHabit()
                        viewModel.alertState.isDeleteAlertPresented = false
                    }
                )
                .freezeHabitAlert(
                    // РЕШЕНИЕ: Создаем явный байндинг для freezeAlert
                    isPresented: Binding<Bool>(
                        get: { viewModel.alertState.isFreezeAlertPresented },
                        set: { viewModel.alertState.isFreezeAlertPresented = $0 }
                    ),
                    onDismiss: {
                        viewModel.isEditSheetPresented = false
                        viewModel.alertState.isFreezeAlertPresented = false
                    }
                )
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
            } else {
                // Показываем ProgressView, пока viewModel не создан
                ProgressView()
            }
        }
        .onAppear {
            setupViewModel()
        }
        .onChange(of: date) { _, newDate in
            // При изменении даты пересоздаем ViewModel
            setupViewModel(with: newDate)
        }
        .onDisappear {
            viewModel?.cleanup(stopTimer: false)
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupViewModel(with newDate: Date? = nil) {
        // Сначала делаем isContentReady = false, чтобы избежать мерцания при обновлении
        isContentReady = false
        
        // Очищаем предыдущий ViewModel при необходимости
        viewModel?.cleanup(stopTimer: true)
        
        // Создаем новый ViewModel с датой
        let vm = HabitDetailViewModel(
            habit: habit,
            date: newDate ?? date,
            modelContext: modelContext,
            habitsUpdateService: habitsUpdateService
        )
        vm.onHabitDeleted = onDelete
        
        // Обновляем ViewModel и активируем контент
        viewModel = vm
        
        // Небольшая задержка для плавности анимации
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            isContentReady = true
        }
    }
}
