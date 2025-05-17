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
        ZStack {
            if let viewModel = viewModel, isContentReady {
                // Основной контейнер с фиксированной структурой
                VStack(spacing: 0) {
                    // Заголовок и информация о цели
                    VStack(spacing: 4) {
                        Text(habit.title)
                            .font(.title2.bold())
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        Text("goal".localized(with: viewModel.formattedGoal))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 10)
                    
                    ProgressControlSection(
                        habit: habit,
                        currentProgress: .constant(viewModel.currentProgress),
                        completionPercentage: viewModel.completionPercentage,
                        formattedProgress: viewModel.formattedProgress,
                        onIncrement: viewModel.incrementProgress,
                        onDecrement: viewModel.decrementProgress
                    )
                    .padding(.vertical, 5)

                    ActionButtonsSection(
                        habit: habit,
                        isTimerRunning: viewModel.isTimerRunning,
                        onReset: {
                            viewModel.resetProgress()
                            viewModel.alertState.errorFeedbackTrigger.toggle()
                        },
                        onTimerToggle: {
                            // Только для таймера
                            viewModel.toggleTimer()
                        },
                        onManualEntry: {
                            // Разная логика в зависимости от типа привычки
                            if habit.type == .time {
                                viewModel.alertState.isTimeAlertPresented = true
                            } else {
                                viewModel.alertState.isCountAlertPresented = true
                            }
                        }
                    )
                    
                    Spacer(minLength: 16)
                    
                    // Кнопка "Завершить" внизу экрана
                    Button(action: {
                        viewModel.completeHabit()
                    }) {
                        Text(viewModel.isAlreadyCompleted ? "completed".localized : "complete".localized)
                            .font(.headline)
                            .foregroundStyle(
                                colorScheme == .dark ? .black : .white
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                viewModel.isAlreadyCompleted
                                ? Color.gray
                                : (colorScheme == .dark
                                   ? Color.white.opacity(0.8)
                                   : Color.black)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(viewModel.isAlreadyCompleted)
                    .modifier(HapticManager.shared.sensoryFeedback(.impact(weight: .medium), trigger: !viewModel.isAlreadyCompleted))
                    .padding(.horizontal)
                    .padding(.bottom, 16)
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
                .habitAlerts(
                    alertState: Binding<AlertState>(
                        get: { viewModel.alertState },
                        set: { viewModel.alertState = $0 }
                    ),
                    habit: habit,
                    progressService: viewModel.progressService,
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
            } else {
                // Индикатор загрузки по центру
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        // Модификаторы применяем к родительскому ZStack
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("") // Пустой заголовок
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
                    Image(systemName: "chart.pie")
                        .foregroundStyle(.secondary)
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
                    .tint(.red)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            setupViewModel()
        }
        .onChange(of: date) { _, newDate in
            viewModel?.saveIfNeeded()
            setupViewModel(with: newDate)
        }
        .onDisappear {
            if !isManuallyDismissing {
                viewModel?.saveIfNeeded()
                viewModel?.cleanup(stopTimer: true)
            }
        }
        .alert("close_habit_detail".localized, isPresented: $isTimerStopAlertPresented) {
            Button("cancel".localized, role: .cancel) { }
            Button("close".localized, role: .destructive) {
                isManuallyDismissing = true
                viewModel?.saveIfNeeded()
                viewModel?.cleanup(stopTimer: true)
                dismiss()
            }
        }
        .sheet(isPresented: $isEditPresented) {
            NewHabitView(habit: habit)
        }
        .interactiveDismissDisabled(viewModel?.isTimerRunning == true)
    }
    
    // MARK: - Helper Methods
    private func setupViewModel(with newDate: Date? = nil) {
        isContentReady = false
        viewModel?.saveIfNeeded()
        viewModel?.cleanup(stopTimer: false)
        
        let vm = HabitDetailViewModel(
            habit: habit,
            date: newDate ?? date,
            modelContext: modelContext,
            habitsUpdateService: habitsUpdateService
        )
        vm.onHabitDeleted = onDelete
        
        viewModel = vm
        isContentReady = true
    }
}
