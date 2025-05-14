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
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Закрыть") {
                    dismiss()
                }
            }
        }
        .onChange(of: selectedDate) { oldDate, newDate in
            // Теперь обработка выбора даты происходит через contextMenu в MonthlyCalendarView
        }
        .onChange(of: habitsUpdateService.lastUpdateTimestamp) { _, _ in
            viewModel.calculateStats()
            
            // Отправляем уведомление об обновлении прогресса привычки через DispatchQueue.main
            // чтобы убедиться, что оно обрабатывается в главном потоке
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .habitProgressUpdated, object: habit.id)
            }
        }
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
    
    private func completeHabit() {
        if detailViewModel == nil {
            createDetailViewModel(for: selectedDate)
        }
        
        detailViewModel?.completeHabit()
        viewModel.calculateStats()
        
        // Отправляем уведомление об обновлении прогресса привычки
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .habitProgressUpdated, object: habit.id)
        }
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
        
        // Отправляем уведомление об обновлении прогресса привычки
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .habitProgressUpdated, object: habit.id)
        }
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
