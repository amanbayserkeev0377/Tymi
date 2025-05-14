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
    @State private var calendarActionManager = CalendarActionManager()
    
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
                MonthlyCalendarView(habit: habit, selectedDate: $selectedDate)
                    .listRowInsets(EdgeInsets())
                    .environment(\.calendarActionManager, calendarActionManager)
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
            
            habitsUpdateService.triggerUpdate()

        }
        // Добавляем обработчик для CalendarActionManager
        .onChange(of: calendarActionManager.actionType) { _, newValue in
            guard let actionType = newValue,
                  let habit = calendarActionManager.habit,
                  let date = calendarActionManager.date else { return }
            
            // Проверяем, что это наша привычка
            guard habit.id == self.habit.id else { return }
            
            // Обрабатываем действие
            switch actionType {
            case .complete:
                completeHabitDirectly(for: date)
            case .addProgress:
                // Показываем соответствующий алерт в зависимости от типа привычки
                if habit.type == .count {
                    alertState.isCountAlertPresented = true
                } else {
                    alertState.isTimeAlertPresented = true
                }
            }
            
            // Очищаем действие после обработки
            calendarActionManager.clear()
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
    }
    
    // Методы для обработки ввода
    // В HabitStatisticsView.swift
    private func handleCountInput() {
        guard let date = calendarActionManager.date else { return }
        guard let count = Int(alertState.countInputText), count > 0 else {
            alertState.errorFeedbackTrigger.toggle()
            alertState.countInputText = ""
            return
        }
        
        // Создаем временный ViewModel
        let tempViewModel = HabitDetailViewModel(
            habit: habit,
            date: date,
            modelContext: modelContext,
            habitsUpdateService: habitsUpdateService
        )
        
        tempViewModel.alertState.countInputText = alertState.countInputText
        tempViewModel.handleCountInput()
        viewModel.calculateStats()
        
        // Вызываем обновление UI через сервис
        habitsUpdateService.triggerUpdate()
        
        // Очищаем поле ввода
        alertState.countInputText = ""
    }
    
    private func handleTimeInput() {
        guard let date = calendarActionManager.date else { return }
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
        
        // Обновляем статистику
        viewModel.calculateStats()
        
        // Вызываем обновление UI через сервис
        habitsUpdateService.triggerUpdate()
        
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
        habitsUpdateService.triggerUpdate()
        
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
