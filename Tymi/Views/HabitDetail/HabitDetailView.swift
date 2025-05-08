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
    // Дополнительные состояния для sheet и alerts
    @State private var isEditSheetPresented = false
    @State private var alertState = AlertState()
    
    // MARK: - Body
    var body: some View {
        ZStack {
            if let viewModel = viewModel {
                VStack(spacing: 15) {
                    // Header with close and menu buttons
                    HStack {
                        Spacer()
                        
                        Text(habit.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Menu {
                            Button {
                                isEditSheetPresented = true
                            } label: {
                                Label("edit".localized, systemImage: "pencil")
                            }
                            
                            Button {
                                viewModel.toggleFreeze()
                            } label: {
                                Label(habit.isFreezed ? "unfreeze".localized : "freeze".localized, systemImage: habit.isFreezed ? "flame" : "snowflake")
                            }
                            
                            Button(role: .destructive) {
                                alertState.isDeleteAlertPresented = true
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
                        onReset: { alertState.isResetAlertPresented = true },
                        onTimerToggle: {
                            if habit.type == .time {
                                viewModel.toggleTimer()
                            } else {
                                alertState.isCountAlertPresented = true
                            }
                        },
                        onManualEntry: {
                            alertState.isTimeAlertPresented = true
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
                // Используем onChange для синхронизации ViewModel -> View
                .onChange(of: viewModel.isEditSheetPresented) { _, newValue in
                    isEditSheetPresented = newValue
                }
                // Это важно для синхронизации View -> ViewModel
                .onChange(of: isEditSheetPresented) { _, newValue in
                    viewModel.isEditSheetPresented = newValue
                }
            } else {
                // Показываем ProgressView, пока viewModel не создан
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                // Создаем viewModel только один раз
                let vm = HabitDetailViewModel(
                    habit: habit,
                    date: date,
                    modelContext: modelContext,
                    habitsUpdateService: habitsUpdateService
                )
                vm.onHabitDeleted = onDelete
                self.viewModel = vm
                
                // После создания viewModel инициализируем локальные состояния
                self.isEditSheetPresented = vm.isEditSheetPresented
                self.alertState = vm.alertState
            }
        }
        // Используем наши локальные состояния для модификаторов
        .sheet(isPresented: $isEditSheetPresented) {
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
            alertState: $alertState,
            habit: habit,
            timerService: viewModel?.timerService ?? .shared,
            onReset: {
                viewModel?.resetProgress()
                // Обновление локального состояния после сброса
                alertState.isResetAlertPresented = false
            },
            onDelete: {
                viewModel?.deleteHabit()
                // Обновление локального состояния после удаления
                alertState.isDeleteAlertPresented = false
            }
        )
        .freezeHabitAlert(isPresented: $alertState.isFreezeAlertPresented) {
            isEditSheetPresented = false
            alertState.isFreezeAlertPresented = false
        }
        .onDisappear {
            viewModel?.cleanup()
        }
        // Наблюдаем за изменениями в локальном состоянии alertState
        .onChange(of: alertState.successFeedbackTrigger) { _, newValue in
            if newValue {
                HapticManager.shared.play(.success)
                // Здесь же обновляем и viewModel при необходимости
                viewModel?.alertState.successFeedbackTrigger = newValue
            }
        }
        .onChange(of: alertState.errorFeedbackTrigger) { _, newValue in
            if newValue {
                HapticManager.shared.play(.error)
                // Здесь же обновляем и viewModel при необходимости
                viewModel?.alertState.errorFeedbackTrigger = newValue
            }
        }
        // Синхронизация модификаторов с ViewModel
        .onChange(of: viewModel?.alertState) { _, newAlertState in
            if let newAlertState = newAlertState {
                alertState = newAlertState
            }
        }
    }
}
