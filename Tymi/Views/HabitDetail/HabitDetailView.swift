import SwiftUI
import SwiftData

struct HabitDetailView: View {
    // MARK: - Properties
    let habit: Habit
    let date: Date
    var onDelete: (() -> Void)?
    var onShowStats: (() -> Void)?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State Properties
    @State private var viewModel: HabitDetailViewModel?
    @State private var isContentReady = false
    @State private var navigateToStatistics = false
    @State private var isEditPresented = false
    @State private var isTimerStopAlertPresented = false
    @State private var isManuallyDismissing = false
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            if let viewModel = viewModel, isContentReady {
                VStack(spacing: 15) {
                    // Goal header
                    Text("goal".localized(with: viewModel.formattedGoal))
                        .font(.subheadline)
                        .padding(.top, 8)
                    
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
                    
                    Spacer(minLength: 24)
                    
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
                .habitAlerts(
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
                        if let onDelete = onDelete {
                            onDelete()
                        } else {
                            dismiss()
                        }
                    },
                    onCountInput: {
                        viewModel.handleCountInput()
                        viewModel.alertState.isCountAlertPresented = false
                    },
                    onTimeInput: {
                        viewModel.handleTimeInput()
                        viewModel.alertState.isTimeAlertPresented = false
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
        .navigationTitle(habit.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Кнопка "Закрыть" только если таймер активен
            ToolbarItem(placement: .cancellationAction) {
                if viewModel?.isTimerRunning == true {
                    Button("close".localized) {
                        isTimerStopAlertPresented = true
                    }
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if let onShowStats = onShowStats {
                        onShowStats()
                    }
                } label: {
                    Image(systemName: "chart.bar")
                }
            }
            
            // Меню с действиями справа
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    // Кнопка редактирования
                    Button {
                        isEditPresented = true
                    } label: {
                        Label("edit".localized, systemImage: "pencil")
                    }
                    
                    // Кнопка удаления
                    Button(role: .destructive) {
                        viewModel?.alertState.isDeleteAlertPresented = true
                    } label: {
                        Label("delete".localized, systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .onAppear {
            setupViewModel()
        }
        .onChange(of: date) { _, newDate in
            // При изменении даты пересоздаем ViewModel
            // Сохраняем текущие изменения перед созданием нового ViewModel
            viewModel?.saveIfNeeded()
            setupViewModel(with: newDate)
        }
        .onDisappear {
            if !isManuallyDismissing {
                viewModel?.saveIfNeeded()
                viewModel?.cleanup(stopTimer: true)
            }
        }
        .alert("close_detail_view".localized, isPresented: $isTimerStopAlertPresented) {
            Button("cancel".localized, role: .cancel) { }
            Button("stop_and_exit".localized, role: .destructive) {
                isManuallyDismissing = true
                viewModel?.saveIfNeeded()
                viewModel?.cleanup(stopTimer: true)
                dismiss()
            }
        } message: {
            Text("stop_timer_message".localized)
        }
        // Добавляем sheet для редактирования
        .sheet(isPresented: $isEditPresented) {
            NewHabitView(habit: habit)
        }
        // Блокируем интерактивное закрытие при активном таймере
        .interactiveDismissDisabled(viewModel?.isTimerRunning == true)
    }
    
    // MARK: - Helper Methods
    
    private func setupViewModel(with newDate: Date? = nil) {
        // Сначала делаем isContentReady = false, чтобы избежать мерцания при обновлении
        isContentReady = false
        
        // Сохраняем любые изменения и очищаем предыдущий ViewModel
        viewModel?.saveIfNeeded()
        viewModel?.cleanup(stopTimer: false)
        
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
