import SwiftUI
import SwiftData


struct HabitStatisticsView: View {
    let habit: Habit
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    
    // Состояния для основной статистики
    @State private var currentStreak: Int = 0
    @State private var bestStreak: Int = 0
    @State private var totalCompleted: Int = 0
    @State private var completionRate: Double = 0
    
    // Состояния для календаря
    @State private var selectedMonth: Date = Date()
    @State private var calendarDays: [CalendarDay] = []
    @State private var selectedDate: Date? = nil
    
    // Состояния для алертов
    @State private var alertState = AlertState()
    @State private var progressService: ProgressTrackingService?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Информация о привычке
                HabitHeaderView(habit: habit)
                    .padding(.horizontal)
                
                // Основная статистика
                HStack(spacing: 15) {
                    StatCard(
                        title: "Серия",
                        value: "\(currentStreak)",
                        subtitle: "дней подряд",
                        icon: "flame.fill",
                        iconColor: .orange
                    )
                    
                    StatCard(
                        title: "Рекорд",
                        value: "\(bestStreak)",
                        subtitle: "дней",
                        icon: "trophy.fill",
                        iconColor: .yellow
                    )
                    
                    StatCard(
                        title: "Всего",
                        value: "\(totalCompleted)",
                        subtitle: "выполнено",
                        icon: "checkmark.circle.fill",
                        iconColor: .green
                    )
                }
                .padding(.horizontal)
                
                // Месячный календарь
                VStack(spacing: 8) {
                    // Заголовок месяца с навигацией
                    HStack {
                        Button(action: showPreviousMonth) {
                            Image(systemName: "chevron.left")
                        }
                        
                        Spacer()
                        
                        Text(monthYearFormatter.string(from: selectedMonth))
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: showNextMonth) {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(isNextMonthDisabled)
                    }
                    .padding(.horizontal)
                    
                    // Дни недели
                    HStack {
                        ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // Сетка дней
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                        // Пустые ячейки в начале месяца
                        ForEach(0..<firstWeekdayOfMonth, id: \.self) { _ in
                            Color.clear
                                .aspectRatio(1, contentMode: .fit)
                        }
                        
                        // Дни месяца
                        ForEach(calendarDays) { day in
                            CalendarDayView(
                                day: day,
                                isSelected: selectedDate != nil && Calendar.current.isDate(day.date, inSameDayAs: selectedDate!)
                            )
                            .onTapGesture {
                                if day.isActive {
                                    selectedDate = day.date
                                    setupEditForDate(day.date)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.primary.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Секция добавления прогресса для выбранной даты
                if let selectedDate = selectedDate {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Прогресс на \(dateFormatter.string(from: selectedDate))")
                            .font(.headline)
                        
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                if habit.type == .count {
                                    alertState.isCountAlertPresented = true
                                } else {
                                    alertState.isTimeAlertPresented = true
                                }
                            }) {
                                Text("Добавить прогресс")
                                    .padding()
                                    .background(Color.primary.opacity(0.1))
                                    .cornerRadius(10)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            calculateStatistics()
            updateCalendarData()
        }
        .onChange(of: selectedMonth) { _, _ in
            updateCalendarData()
        }
        .navigationTitle("Статистика")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Закрыть") {
                    dismiss()
                }
            }
        }
        .habitAlerts(
            alertState: $alertState,
            habit: habit,
            progressService: progressService ?? ProgressServiceProvider.getService(for: habit),
            onReset: {},  // Эта функция не используется в статистике
            onDelete: {}, // Эта функция не используется в статистике
            onCountInput: handleCountInput,
            onTimeInput: handleTimeInput
        )
    }
    
    // Вспомогательные вычисляемые свойства для календаря
    private var firstWeekdayOfMonth: Int {
        let components = Calendar.current.dateComponents([.year, .month], from: selectedMonth)
        guard let firstDay = Calendar.current.date(from: components) else { return 0 }
        return (Calendar.current.component(.weekday, from: firstDay) - Calendar.current.firstWeekday + 7) % 7
    }
    
    private var isNextMonthDisabled: Bool {
        let currentMonth = Calendar.current.dateComponents([.year, .month], from: Date())
        let selectedMonthComp = Calendar.current.dateComponents([.year, .month], from: selectedMonth)
        
        return selectedMonthComp.year! > currentMonth.year! ||
               (selectedMonthComp.year! == currentMonth.year! &&
                selectedMonthComp.month! >= currentMonth.month!)
    }
    
    // MARK: - Методы
    
    private func calculateStatistics() {
        // Вычисление текущей серии, лучшей серии и общего количества
        let calendar = Calendar.current
        let now = Date()
        
        // Получаем все даты завершения
        var completedDates: [Date] = []
        
        // Фильтруем завершенные дни
        for completion in habit.completions {
            if completion.value >= habit.goal {
                completedDates.append(completion.date)
            }
        }
        
        // Сортируем даты
        completedDates.sort()
        
        // Вычисляем общее количество завершений
        totalCompleted = completedDates.count
        
        // Вычисляем текущую и лучшую серии
        var currentStreakCount = 0
        var bestStreakCount = 0
        var tempStreak = 0
        
        // Проверяем, выполнена ли привычка сегодня
        let isCompletedToday = habit.isCompletedForDate(now)
        
        // Идем назад от сегодняшнего дня
        var checkDate = isCompletedToday ? now : Calendar.current.date(byAdding: .day, value: -1, to: now)!
        
        // Вычисляем текущую серию
        while true {
            // Проверяем только дни, когда привычка активна
            if habit.isActiveOnDate(checkDate) {
                // Проверяем, выполнена ли привычка в этот день
                let isCompleted = completedDates.contains { calendar.isDate($0, inSameDayAs: checkDate) }
                
                if isCompleted {
                    currentStreakCount += 1
                } else {
                    break // Серия прервана
                }
            }
            
            // Переходим к предыдущему дню
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDate
            
            // Проверка на startDate
            if checkDate < habit.startDate {
                break
            }
        }
        
        // Вычисляем лучшую серию
        checkDate = habit.startDate
        
        while checkDate <= now {
            if habit.isActiveOnDate(checkDate) {
                let isCompleted = completedDates.contains { calendar.isDate($0, inSameDayAs: checkDate) }
                
                if isCompleted {
                    tempStreak += 1
                    bestStreakCount = max(bestStreakCount, tempStreak)
                } else {
                    tempStreak = 0
                }
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: checkDate) else { break }
            checkDate = nextDate
        }
        
        currentStreak = currentStreakCount
        bestStreak = bestStreakCount
        
        // Вычисляем процент выполнения
        let daysSinceStart = calendar.dateComponents([.day], from: habit.startDate, to: now).day ?? 0
        
        if daysSinceStart > 0 {
            // Считаем только активные дни
            var activeDays = 0
            checkDate = habit.startDate
            
            while checkDate <= now {
                if habit.isActiveOnDate(checkDate) {
                    activeDays += 1
                }
                
                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: checkDate) else { break }
                checkDate = nextDate
            }
            
            completionRate = activeDays > 0 ? Double(totalCompleted) / Double(activeDays) : 0
        } else {
            completionRate = 0
        }
    }
    
    private func updateCalendarData() {
        let calendar = Calendar.current
        
        // Получаем первый и последний день месяца
        let components = calendar.dateComponents([.year, .month], from: selectedMonth)
        guard let startOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return
        }
        
        let numberOfDays = range.count
        
        // Создаем данные для дней календаря
        var days: [CalendarDay] = []
        
        for day in 1...numberOfDays {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) else {
                continue
            }
            
            // Определяем статус дня
            let isActive = date >= habit.startDate && date <= Date() && habit.isActiveOnDate(date)
            let isCompleted = habit.isCompletedForDate(date)
            
            days.append(CalendarDay(
                date: date,
                dayNumber: day,
                isActive: isActive,
                isCompleted: isCompleted,
                progress: habit.completionPercentageForDate(date)
            ))
        }
        
        calendarDays = days
    }
    
    private func showPreviousMonth() {
        guard let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) else {
            return
        }
        
        // Не показываем месяцы до даты начала привычки
        let startMonthComponents = Calendar.current.dateComponents([.year, .month], from: habit.startDate)
        let newMonthComponents = Calendar.current.dateComponents([.year, .month], from: newDate)
        
        if newMonthComponents.year! < startMonthComponents.year! ||
           (newMonthComponents.year! == startMonthComponents.year! &&
            newMonthComponents.month! < startMonthComponents.month!) {
            return
        }
        
        selectedMonth = newDate
    }
    
    private func showNextMonth() {
        guard let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) else {
            return
        }
        
        // Не показываем будущие месяцы после текущего
        let currentMonthComponents = Calendar.current.dateComponents([.year, .month], from: Date())
        let newMonthComponents = Calendar.current.dateComponents([.year, .month], from: newDate)
        
        if newMonthComponents.year! > currentMonthComponents.year! ||
           (newMonthComponents.year! == currentMonthComponents.year! &&
            newMonthComponents.month! > currentMonthComponents.month!) {
            return
        }
        
        selectedMonth = newDate
    }
    
    private func setupEditForDate(_ date: Date) {
        // Создаем соответствующий сервис для выбранной даты
        let initialProgress = habit.progressForDate(date)
        progressService = ProgressServiceProvider.getLocalService(
            for: habit,
            date: date,
            initialProgress: initialProgress,
            onUpdate: {}
        )
    }
    
    private func handleCountInput() {
        guard let selectedDate = selectedDate, let progressService = progressService else {
            return
        }
        
        // Получаем введенное значение
        guard let value = Int(alertState.countInputText), value > 0 else {
            HapticManager.shared.play(.error)
            alertState.countInputText = ""
            return
        }
        
        // Добавляем прогресс
        progressService.resetProgress(for: habit.uuid.uuidString)
        progressService.addProgress(value, for: habit.uuid.uuidString)
        
        // Сохраняем в базу данных
        progressService.persistCompletions(
            for: habit.uuid.uuidString,
            in: modelContext,
            date: selectedDate
        )
        
        // Обновляем статистику и календарь
        calculateStatistics()
        updateCalendarData()
        
        // Триггерим обновление UI
        habitsUpdateService.triggerUpdate()
        
        // Обратная связь
        HapticManager.shared.play(.success)
        alertState.countInputText = ""
    }
    
    private func handleTimeInput() {
        guard let selectedDate = selectedDate, let progressService = progressService else {
            return
        }
        
        // Получаем введенные часы и минуты
        let hours = Int(alertState.hoursInputText) ?? 0
        let minutes = Int(alertState.minutesInputText) ?? 0
        
        if hours == 0 && minutes == 0 {
            HapticManager.shared.play(.error)
            return
        }
        
        // Преобразуем в секунды
        let secondsToAdd = hours * 3600 + minutes * 60
        
        // Добавляем прогресс
        progressService.resetProgress(for: habit.uuid.uuidString)
        progressService.addProgress(secondsToAdd, for: habit.uuid.uuidString)
        
        // Сохраняем в базу данных
        progressService.persistCompletions(
            for: habit.uuid.uuidString,
            in: modelContext,
            date: selectedDate
        )
        
        // Обновляем статистику и календарь
        calculateStatistics()
        updateCalendarData()
        
        // Триггерим обновление UI
        habitsUpdateService.triggerUpdate()
        
        // Обратная связь
        HapticManager.shared.play(.success)
        alertState.hoursInputText = ""
        alertState.minutesInputText = ""
    }
    
    // MARK: - Форматтеры
    
    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - Вспомогательные структуры и компоненты

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let dayNumber: Int
    let isActive: Bool
    let isCompleted: Bool
    let progress: Double
}

struct CalendarDayView: View {
    let day: CalendarDay
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.primary : Color.clear, lineWidth: isSelected ? 2 : 0)
                )
            
            Text("\(day.dayNumber)")
                .font(.callout)
                .foregroundColor(textColor)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(4)
        .opacity(day.isActive ? 1.0 : 0.4)
    }
    
    private var backgroundColor: Color {
        if !day.isActive {
            return Color.clear
        } else if day.isCompleted {
            return Color.green.opacity(0.3)
        } else {
            return Color.orange.opacity(0.3)
        }
    }
    
    private var textColor: Color {
        if !day.isActive {
            return Color.secondary
        } else {
            return Color.primary
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(iconColor)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(12)
    }
}

struct HabitHeaderView: View {
    let habit: Habit
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(habit.formattedGoal)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let iconName = habit.iconName {
                Image(systemName: iconName)
                    .font(.system(size: 30))
                    .frame(width: 54, height: 54)
                    .background(Color.primary.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
}
