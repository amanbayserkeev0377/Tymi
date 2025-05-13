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
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State Properties
    @State private var viewModel: HabitDetailViewModel?
    @State private var isContentReady = false
    @State private var isStatisticsPresented = false
    @State private var isEditPresented = false
    
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
                        dismiss() // Возвращаемся назад при удалении
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
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    // Кнопка статистики
                    Button {
                        isStatisticsPresented = true
                    } label: {
                        Label("statistics".localized, systemImage: "chart.bar")
                    }
                    
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
            setupViewModel(with: newDate)
        }
        .onDisappear {
            viewModel?.cleanup(stopTimer: false) // Не останавливаем таймер при уходе с экрана
        }
        // Добавляем sheet для статистики
        .sheet(isPresented: $isStatisticsPresented) {
            // Временный заглушка для статистики
            NavigationStack {
                Text("Здесь будет статистика привычки")
                    .navigationTitle("habit_statistics".localized)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("close".localized) {
                                isStatisticsPresented = false
                            }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        // Добавляем sheet для редактирования, используя ваш обновленный NewHabitView
        .sheet(isPresented: $isEditPresented) {
            NewHabitView(habit: habit)
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
