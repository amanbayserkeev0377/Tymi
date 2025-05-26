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
            } else {
                loadingView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { habitDetailToolbar }
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
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func habitDetailContent(viewModel: HabitDetailViewModel) -> some View {
        VStack(spacing: 0) {
            Text(habit.title)
                .font(.largeTitle.bold())
                .lineLimit(1)
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
                if iconName.hasPrefix("icon_") {
                    // Кастомная иконка
                    Image(iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.secondary)
                } else {
                    // SF Symbol
                    Image(systemName: iconName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
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
                    ? Color(uiColor: .systemGray)
                    : Color.primary.opacity(0.8)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(viewModel.isAlreadyCompleted)
        .modifier(HapticManager.shared.sensoryFeedback(.impact(weight: .medium), trigger: !viewModel.isAlreadyCompleted))
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemBackground))
    }
    
    // Индикатор загрузки
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }
    
    // Toolbar
    @ToolbarContentBuilder
    private var habitDetailToolbar: some ToolbarContent {
        // Кнопка "Закрыть" только если таймер активен
        ToolbarItem(placement: .cancellationAction) {
            if viewModel?.isTimerRunning == true {
                XmarkView {
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
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.8))
                            .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
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
}
