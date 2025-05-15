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
            // Основные метрики
            StreaksView(viewModel: viewModel)
            
            // Календарь месяца
            Section {
                MonthlyCalendarView(
                    habit: habit,
                    selectedDate: $selectedDate,
                    updateCounter: updateCounter,
                    onActionRequested: handleCalendarAction
                )
                .listRowInsets(EdgeInsets())
            }
            
            // Информация о привычке
            Section {
                // Дата начала
                LabeledContent("Дата начала") {
                    Text(dateFormatter.string(from: habit.startDate))
                }
                
                // Цель
                LabeledContent("Цель") {
                    Text(habit.formattedGoal)
                }
                
                // Активные дни
                LabeledContent("Активные дни") {
                    Text(formattedActiveDays)
                }
            } header: {
                Text("Информация о привычке")
            }
            
            // Кнопка сброса истории
            Section {
                Button(role: .destructive) {
                    showingResetAlert = true
                } label: {
                    Text("Сбросить историю привычки")
                        .frame(maxWidth: .infinity, alignment: .center)
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
        .onChange(of: habitsUpdateService.lastUpdateTimestamp) { _, _ in
            viewModel.calculateStats()
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
            onDelete: { /* Не используется */ },
            onCountInput: {
                handleCountInput()
            },
            onTimeInput: {
                handleTimeInput()
            }
        )
        .alert("Сбросить историю?", isPresented: $showingResetAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Сбросить", role: .destructive) {
                resetHabitHistory()
            }
        } message: {
            Text("Это действие удалит всю историю выполнения привычки. Это действие нельзя отменить.")
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
        
        // Принудительно обновляем UI календаря
        updateCounter += 1
        
        // Очищаем поля ввода
        alertState.hoursInputText = ""
        alertState.minutesInputText = ""
    }
    
    private func resetHabitHistory() {
        // Удаляем все записи о выполнении привычки
        for completion in habit.completions {
            modelContext.delete(completion)
        }
        
        // Сохраняем изменения
        try? modelContext.save()
        
        // Обновляем статистику
        viewModel.calculateStats()
        
        // Триггерим обновление UI через сервис
        habitsUpdateService.triggerUpdate()
        
        // Обновляем UI календаря
        updateCounter += 1
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
