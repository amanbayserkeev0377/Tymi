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
    
    private var isSmallDevice: Bool {
        UIScreen.main.bounds.width <= 375
    }
    
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
                habitDetailContent(viewModel: viewModel)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { habitDetailToolbar }
                    .onAppear {
                        setupViewModel()
                    }
                    .onChange(of: date) { _, newDate in
                        viewModel.saveIfNeeded()
                        setupViewModel(with: newDate)
                    }
                    .onDisappear {
                        if !isManuallyDismissing {
                            viewModel.saveIfNeeded()
                            viewModel.cleanup(stopTimer: true)
                        } else {
                            viewModel.forceCleanup()
                        }
                    }
                    .alert("alert_close_timer".localized, isPresented: $isTimerStopAlertPresented) {
                        Button("button_cancel".localized, role: .cancel) { }
                        Button("button_close".localized, role: .destructive) {
                            isManuallyDismissing = true
                            viewModel.saveIfNeeded()
                            viewModel.cleanup(stopTimer: true)
                            dismiss()
                        }
                    }
                    .sheet(isPresented: $isEditPresented) {
                        NewHabitView(habit: habit)
                    }
                    .interactiveDismissDisabled(viewModel.isTimerRunning == true)
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                        viewModel.saveIfNeeded()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                        viewModel.refreshFromService()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                        viewModel.forceCleanup()
                    }
            } else {
                ProgressView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { habitDetailToolbar }
                    .onAppear {
                        setupViewModel()
                    }
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func habitDetailContent(viewModel: HabitDetailViewModel) -> some View {
        VStack(spacing: 0) {
            Text(habit.title)
                .font(.largeTitle.bold())
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .padding(.horizontal)
                .padding(.top, 0)
                .padding(.bottom, 4)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityHeading(.h1)
            
            goalInfoView(viewModel: viewModel)
            
            Spacer().frame(height: isSmallDevice ? 20 : 30)
            
            ProgressControlSection(
                habit: habit,
                currentProgress: .constant(viewModel.currentProgress),
                completionPercentage: viewModel.completionPercentage,
                formattedProgress: viewModel.formattedProgress,
                onIncrement: viewModel.incrementProgress,
                onDecrement: viewModel.decrementProgress
            )
            
            Spacer().frame(height: isSmallDevice ? 16 : 24)
            
            actionButtonsView(viewModel: viewModel)
            
            if isSmallDevice {
                Spacer().frame(height: 20)
            } else {
                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom) {
            completeButtonView(viewModel: viewModel)
                .padding(.bottom, isSmallDevice ? 0 : 8)
                .padding(.vertical, isSmallDevice ? 4 : 8)
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
    }
    
    // Информация о цели привычки - центрированная с иконкой
    private func goalInfoView(viewModel: HabitDetailViewModel) -> some View {
        // Центрированный контейнер с иконкой (если она есть) и текстом
        HStack(spacing: 8) {
            // Иконка слева от текста Goal (если она установлена)
            if let iconName = habit.iconName {
                Image(systemName: iconName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Текст goal по центру
            Text("goal".localized(with: viewModel.formattedGoal))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
    }
    
    // Секция с кнопками действий
    private func actionButtonsView(viewModel: HabitDetailViewModel) -> some View {
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
    }
    
    // Complete
    private func completeButtonView(viewModel: HabitDetailViewModel) -> some View {
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
                    ? AppColorManager.shared.selectedColor.color.opacity(0.3)
                    : AppColorManager.shared.selectedColor.color.opacity(0.8)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(viewModel.isAlreadyCompleted)
        .modifier(HapticManager.shared.sensoryFeedback(.impact(weight: .medium), trigger: !viewModel.isAlreadyCompleted))
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemBackground))
    }
        
    // Toolbar
    @ToolbarContentBuilder
    private var habitDetailToolbar: some ToolbarContent {
        // Кнопка "Закрыть" только если таймер активен
        ToolbarItem(placement: .cancellationAction) {
            if viewModel?.isTimerRunning == true {
                Button("button_close".localized) {
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
                Image(systemName: "chart.line.text.clipboard")
                    .font(.system(size: 16))
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
                    Label("button_edit".localized, systemImage: "pencil")
                }
                
                // Кнопка архивирования
                Button {
                    archiveHabit()
                } label: {
                    Label("archive".localized, systemImage: "archivebox")
                }
                
                // Кнопка удаления
                Button(role: .destructive) {
                    viewModel?.alertState.isDeleteAlertPresented = true
                } label: {
                    Label("button_delete".localized, systemImage: "trash")
                }
                .tint(.red)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(AppColorManager.shared.selectedColor.color.opacity(0.1))
                    )
            }
        }
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
    
    private func archiveHabit() {
        habit.isArchived = true
        try? modelContext.save()
        habitsUpdateService.triggerUpdate()
        HapticManager.shared.play(.success)
        
        if let onDelete = onDelete {
            onDelete()
        } else {
            dismiss()
        }
    }
}
