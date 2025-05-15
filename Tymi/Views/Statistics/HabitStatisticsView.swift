import SwiftUI
import SwiftData

struct HabitStatisticsView: View {
    // MARK: - Properties
    let habit: Habit
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    
    // MARK: - State
    @State private var selectedDate: Date = Date()
    @State private var viewModel: HabitStatsViewModel
    @State private var detailViewModel: HabitDetailViewModel?
    @State private var showingResetAlert = false
    @State private var alertState = AlertState()
    @State private var updateCounter = 0 // Счётчик обновлений для UI
    
    // MARK: - Initialization
    init(habit: Habit) {
        self.habit = habit
        self._viewModel = State(initialValue: HabitStatsViewModel(habit: habit))
    }
    
    // MARK: - Body
    var body: some View {
        List {
            // Streaks
            StreaksView(viewModel: viewModel)
            
            // Monthly Calendar
            Section {
                MonthlyCalendarView(
                    habit: habit,
                    selectedDate: $selectedDate,
                    updateCounter: updateCounter,
                    onActionRequested: handleCalendarAction
                )
                .listRowInsets(EdgeInsets())
                .frame(maxWidth: .infinity)
            }
            .listSectionSeparator(.hidden)
            
            Section {
                // Start date
                HStack {
                    Label(
                        title: { Text("start_date".localized) },
                        icon: { Image(systemName: "calendar.badge.clock") }
                    )
                    
                    Spacer()
                    
                    Text(dateFormatter.string(from: habit.startDate))
                        .foregroundStyle(.secondary)
                }
                
                // Goal
                HStack {
                    Label(
                        title: { Text("daily_goal".localized) },
                        icon: { Image(systemName: "trophy") }
                    )
                    
                    Spacer()
                    
                    Text(habit.formattedGoal)
                        .foregroundStyle(.secondary)
                }
                
                // Active days
                HStack {
                    Label(
                        title: { Text("active_days".localized) },
                        icon: { Image(systemName: "cloud.sun") }
                    )
                    
                    Spacer()
                    
                    Text(formattedActiveDays)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Reset history
            Section {
                Button {
                    showingResetAlert = true
                } label: {
                    Label("reset_all_history".localized,
                          systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                }
                
                Button(role: .destructive) {
                    alertState.isDeleteAlertPresented = true
                } label: {
                    Label {
                        Text("delete_habit".localized)
                    } icon: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle(habit.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("done".localized) {
                    dismiss()
                }
            }
        }
        .onChange(of: updateCounter) { _, _ in
            // Пересоздаем viewModel для гарантированного обновления
            viewModel = HabitStatsViewModel(habit: habit)
        }
        // Обработчики успеха/ошибки для хаптической обратной связи
        .onChange(of: alertState.successFeedbackTrigger) { _, newValue in
            if newValue {
                HapticManager.shared.play(.success)
            }
        }
        .onChange(of: alertState.errorFeedbackTrigger) { _, newValue in
            if newValue {
                HapticManager.shared.play(.error)
            }
        }
        // Добавляем алерты для ввода прогресса
        .habitAlerts(
            alertState: $alertState,
            habit: habit,
            progressService: ProgressServiceProvider.getService(for: habit),
            onDelete: deleteHabit,
            onCountInput: {
                handleCountInput()
            },
            onTimeInput: {
                handleTimeInput()
            }
        )
        .alert("reset_history", isPresented: $showingResetAlert) {
            Button("cancel".localized, role: .cancel) { }
            Button("reset".localized, role: .destructive) {
                resetHabitHistory()
            }
        } message: {
            Text("reset_history_alert".localized)
        }
    }
    
    // MARK: - Обработка действий календаря
    private func handleCalendarAction(_ action: CalendarAction, date: Date) {
        switch action {
        case .complete:
            completeHabitDirectly(for: date)
        case .addProgress:
            // Сохраняем дату для обработки в алертах
            alertState.date = date
            
            // Показываем соответствующий алерт в зависимости от типа привычки
            if habit.type == .count {
                alertState.isCountAlertPresented = true
            } else {
                alertState.isTimeAlertPresented = true
            }
        case .resetProgress:
            resetProgressDirectly(for: date)
        }
    }
    
    // MARK: - Computed Properties
    
    private var formattedActiveDays: String {
        let weekdays = Calendar.userPreferred.orderedFormattedWeekdaySymbols
        
        let activeDaysWithIndex = zip(habit.activeDays.indices, habit.activeDays)
            .filter { $0.1 } // Фильтруем только активные дни
            .map { (weekdays[$0.0], $0.0) } // Берем имена дней и их индексы
        
        if activeDaysWithIndex.count == 7 {
            return "Ежедневно"
        } else if activeDaysWithIndex.isEmpty {
            return "Нет активных дней"
        } else {
            // Сортируем дни по их индексу в неделе для более понятного отображения
            let sortedDays = activeDaysWithIndex.sorted { $0.1 < $1.1 }
            return sortedDays.map { $0.0 }.joined(separator: ", ")
        }
    }
    
    // MARK: - Methods
    
    private func createDetailViewModel(for date: Date) {
        detailViewModel = HabitDetailViewModel(
            habit: habit,
            date: date,
            modelContext: modelContext,
            habitsUpdateService: habitsUpdateService
        )
    }
    
    // Метод для прямого завершения привычки
    private func completeHabitDirectly(for date: Date) {
        // Создаем временный ViewModel для управления прогрессом привычки
        let tempViewModel = HabitDetailViewModel(
            habit: habit,
            date: date,
            modelContext: modelContext,
            habitsUpdateService: habitsUpdateService
        )
        
        tempViewModel.completeHabit()
        tempViewModel.saveIfNeeded()
        viewModel.calculateStats()
        
        habitsUpdateService.triggerUpdate()
        
        HapticManager.shared.play(.success)
        
        viewModel = HabitStatsViewModel(habit: habit)
        
        updateCounter += 1
    }
    
    // Методы для обработки ввода
    private func handleCountInput() {
        // Получаем дату из alertState
        guard let date = alertState.date, let count = Int(alertState.countInputText), count > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            alertState.countInputText = ""
            return
        }
        
        // Создаем временный ViewModel для обновления данных
        let tempViewModel = HabitDetailViewModel(
            habit: habit,
            date: date,
            modelContext: modelContext,
            habitsUpdateService: habitsUpdateService
        )
        
        tempViewModel.alertState.countInputText = alertState.countInputText
        tempViewModel.handleCountInput()
        tempViewModel.saveIfNeeded()
        
        // Обновляем статистику
        viewModel.calculateStats()
        
        // Триггерим обновление UI через сервис
        habitsUpdateService.triggerUpdate()
        
        viewModel = HabitStatsViewModel(habit: habit)
        
        // Принудительно обновляем UI календаря
        updateCounter += 1
        
        // Очищаем поле ввода
        alertState.countInputText = ""
    }
    
    private func handleTimeInput() {
        guard let date = alertState.date else { return }
        let hours = Int(alertState.hoursInputText) ?? 0
        let minutes = Int(alertState.minutesInputText) ?? 0
        
        if hours == 0 && minutes == 0 {
            alertState.errorFeedbackTrigger.toggle()
            return
        }
        
        // Создаем временный ViewModel
        let tempViewModel = HabitDetailViewModel(
            habit: habit,
            date: date,
            modelContext: modelContext,
            habitsUpdateService: habitsUpdateService
        )
        
        // Копируем данные из alertState
        tempViewModel.alertState.hoursInputText = alertState.hoursInputText
        tempViewModel.alertState.minutesInputText = alertState.minutesInputText
        
        // Обрабатываем ввод
        tempViewModel.handleTimeInput()
        tempViewModel.saveIfNeeded()
        
        // Обновляем статистику
        viewModel.calculateStats()
        
        // Триггерим обновление UI через сервис
        habitsUpdateService.triggerUpdate()
        
        viewModel = HabitStatsViewModel(habit: habit)
        
        // Принудительно обновляем UI календаря
        updateCounter += 1
        
        // Очищаем поля ввода
        alertState.hoursInputText = ""
        alertState.minutesInputText = ""
    }
    
    private func resetProgressDirectly(for date: Date) {
        // Создаем временный ViewModel для управления прогрессом привычки
        let tempViewModel = HabitDetailViewModel(
            habit: habit,
            date: date,
            modelContext: modelContext,
            habitsUpdateService: habitsUpdateService
        )
        
        // Сбрасываем прогресс
        tempViewModel.resetProgress()
        tempViewModel.saveIfNeeded()
        
        // Обновляем статистику
        viewModel.calculateStats()
        
        // Триггерим обновление UI через сервис
        habitsUpdateService.triggerUpdate()
        
        // Воспроизводим хаптик ошибки, как это делается в HabitDetailView
        HapticManager.shared.play(.error)
        
        viewModel = HabitStatsViewModel(habit: habit)
        
        // Принудительно обновляем UI календаря
        updateCounter += 1
    }
    
    private func resetHabitHistory() {
        // Удаляем все записи о выполнении привычки
        for completion in habit.completions {
            modelContext.delete(completion)
        }
        
        // Сохраняем изменения
        try? modelContext.save()
        
        // Пересоздаем viewModel для гарантированного обновления
        viewModel = HabitStatsViewModel(habit: habit)
        
        // Триггерим обновление UI через сервис
        habitsUpdateService.triggerUpdate()
        
        // Обновляем UI календаря
        updateCounter += 1
    }
    
    private func deleteHabit() {
        NotificationManager.shared.cancelNotifications(for: habit)
        modelContext.delete(habit)
        HapticManager.shared.play(.error)
        habitsUpdateService.triggerUpdate()
        dismiss()
    }
    
    // MARK: - Форматтеры
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    private let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
