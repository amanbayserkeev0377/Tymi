import SwiftUI
import SwiftData

enum CalendarAction {
    case complete, addProgress, resetProgress
}

struct MonthlyCalendarView: View {
    // MARK: - Properties
    let habit: Habit
    @Binding var selectedDate: Date
    
    var updateCounter: Int = 0
    var onActionRequested: (CalendarAction, Date) -> Void = { _, _ in }
    
    @Environment(\.modelContext) private var modelContext
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    @Environment(WeekdayPreferences.self) private var weekdayPrefs
    
    // MARK: - State
    @State private var selectedActionDate: Date? = nil
    @State private var showingActionSheet = false
    @State private var months: [Date] = []
    @State private var currentMonthIndex: Int = 0
    @State private var calendarDays: [[Date?]] = []
    @State private var isLoading: Bool = false
    
    // Отслеживаем обновления через @Query
    @Query private var completions: [HabitCompletion]
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    // MARK: - Initialization
    init(habit: Habit, selectedDate: Binding<Date>, updateCounter: Int = 0, onActionRequested: @escaping (CalendarAction, Date) -> Void = { _, _ in }) {
        self.habit = habit
        self._selectedDate = selectedDate
        self.updateCounter = updateCounter
        self.onActionRequested = onActionRequested
        
        // Настраиваем @Query для отслеживания завершений этой привычки
        let habitId = habit.id
        let habitPredicate = #Predicate<HabitCompletion> { completion in
            completion.habit?.id == habitId
        }
        self._completions = Query(filter: habitPredicate)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Заголовок месяца и кнопки навигации в улучшенном макете (название слева, кнопки справа)
            HStack {
                // Название месяца слева
                Text(DateFormatter.capitalizedNominativeMonthYear(from: currentMonth))
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                // Кнопки справа
                HStack(spacing: 16) {
                    Button {
                        if currentMonthIndex > 0 {
                            currentMonthIndex -= 1
                            generateCalendarDays()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(currentMonthIndex > 0 ? .primary : .gray.opacity(0.5))
                            .contentShape(Rectangle())
                            .frame(width: 30, height: 30)
                    }
                    .disabled(currentMonthIndex <= 0)
                    .buttonStyle(BorderlessButtonStyle())
                    
                    Button {
                        // Без анимации для повышения производительности
                        if currentMonthIndex < months.count - 1 && !isNextMonthDisabled {
                            currentMonthIndex += 1
                            generateCalendarDays()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundColor(isNextMonthDisabled ? .gray.opacity(0.5) : .primary)
                            .contentShape(Rectangle())
                            .frame(width: 30, height: 30)
                    }
                    .disabled(isNextMonthDisabled)
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding(.horizontal)
            .zIndex(1)
            
            // Дни недели
            weekdayHeader
            
            // Месячный календарь
            if isLoading {
                ProgressView()
                    .frame(height: 250)
            } else if months.isEmpty || calendarDays.isEmpty {
                Text("loading_calendar".localized)
                    .frame(height: 250)
            } else {
                // Месячная сетка
                VStack {
                    monthGrid(forMonth: currentMonth)
                        .frame(height: min(CGFloat(calendarDays.count) * 55, 300))
                        .id("month-\(currentMonthIndex)-\(updateCounter)") // Уникальный ID обновляет контент
                }
                .background(Color.clear)
            }
        }
        .padding(.vertical)
        .padding(.horizontal, 5)
        .onAppear {
            isLoading = true
            generateMonths()
            findCurrentMonthIndex()
            generateCalendarDays()
            isLoading = false
        }
        // Обновляем при смене выбранной даты (без анимации)
        .onChange(of: selectedDate) { _, newDate in
            if let monthIndex = findMonthIndex(for: newDate) {
                if monthIndex != currentMonthIndex {
                    currentMonthIndex = monthIndex
                    generateCalendarDays()
                }
            }
        }
        // Учитываем внешний счётчик обновлений
        .onChange(of: updateCounter) { _, _ in
            // Принудительно обновляем интерфейс
            generateCalendarDays()
        }
        .onChange(of: weekdayPrefs.firstDayOfWeek) { _, _ in
            generateCalendarDays()
        }
        // Диалог для действий с датой
        .confirmationDialog(
            Text(dateFormatter.string(from: selectedActionDate ?? Date())),
            isPresented: $showingActionSheet,
            titleVisibility: .visible
        ) {
            Button("complete".localized) {
                if let date = selectedActionDate {
                    onActionRequested(.complete, date)
                }
            }
            
            Button("add_progress".localized) {
                if let date = selectedActionDate {
                    onActionRequested(.addProgress, date)
                }
            }
            
            Button(role: .destructive) {
                if let date = selectedActionDate {
                    onActionRequested(.resetProgress, date)
                }
            } label: {
                Text("reset_progress".localized)
            }
            
            Button("cancel".localized, role: .cancel) {}
        }
    }
    
    // MARK: - Components
    
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                Text(calendar.orderedWeekdayInitials[index])
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
    
    private func monthGrid(forMonth month: Date) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
            ForEach(0..<calendarDays.count, id: \.self) { row in
                ForEach(0..<7, id: \.self) { column in
                    if let date = calendarDays[row][column] {
                        // Проверяем, активна ли дата
                        let isActiveDate = date <= Date() && date >= habit.startDate && habit.isActiveOnDate(date)
                        let progress = habit.completionPercentageForDate(date)
                        
                        DayProgressItem(
                            date: date,
                            isSelected: calendar.isDate(selectedDate, inSameDayAs: date),
                            progress: progress,
                            onTap: {
                                selectedDate = date
                                // Показываем действия только для активных дат
                                if isActiveDate {
                                    selectedActionDate = date
                                    showingActionSheet = true
                                }
                            },
                            showProgressRing: isActiveDate // Показываем кольцо только для активных дней
                        )
                        .frame(width: 40, height: 40)
                        // Уникальный ID для элемента дня
                        .id("\(row)-\(column)-\(date.timeIntervalSince1970)-\(progress)-\(updateCounter)")
                        .buttonStyle(BorderlessButtonStyle())
                    } else {
                        Color.clear
                            .frame(width: 40, height: 40)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Helper Properties
    
    private var currentMonth: Date {
        months.isEmpty ? Date() : months[currentMonthIndex]
    }
    
    private var isNextMonthDisabled: Bool {
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: Date())
        let displayedMonthComponents = calendar.dateComponents([.year, .month], from: currentMonth)
        
        return displayedMonthComponents.year! > currentMonthComponents.year! ||
        (displayedMonthComponents.year! == currentMonthComponents.year! &&
         displayedMonthComponents.month! >= currentMonthComponents.month!)
    }
    
    // MARK: - Methods
    
    private func generateMonths() {
        let today = Date()
        
        // Ограничиваем startDate не более чем 1 годом назад
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: today) ?? today
        let effectiveStartDate = max(habit.startDate, oneYearAgo)
        
        // Создаем массив дат для месяцев - сначала получаем компоненты
        let startComponents = calendar.dateComponents([.year, .month], from: effectiveStartDate)
        let todayComponents = calendar.dateComponents([.year, .month], from: today)
        
        // Гарантируем, что у нас есть корректные начальные даты
        guard let startMonth = calendar.date(from: startComponents),
              let currentMonth = calendar.date(from: todayComponents) else {
            months = [today] // Дефолтное значение если что-то пошло не так
            return
        }
        
        var generatedMonths: [Date] = []
        var currentDate = startMonth
        
        // Генерируем месяцы от начала привычки до текущего месяца
        while currentDate <= currentMonth {
            generatedMonths.append(currentDate)
            
            // Добавляем месяц безопасным способом
            guard let nextMonth = calendar.date(byAdding: DateComponents(month: 1), to: currentDate) else {
                break
            }
            currentDate = nextMonth
        }
        
        // Если нет месяцев или слишком мало, генерируем хотя бы текущий
        if generatedMonths.isEmpty {
            generatedMonths = [currentMonth]
        }
        
        months = generatedMonths
    }
    
    private func generateCalendarDays() {
        guard !months.isEmpty && currentMonthIndex < months.count else {
            calendarDays = []
            return
        }
        
        let month = months[currentMonthIndex]
        
        // Получаем количество дней в месяце
        guard let range = calendar.range(of: .day, in: .month, for: month) else {
            calendarDays = []
            return
        }
        let numDays = range.count
        
        // Получаем первый день месяца
        guard let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            calendarDays = []
            return
        }
        
        // Получаем день недели для первого дня месяца (0-6, где 0 - первый день недели в календаре)
        var firstWeekday = calendar.component(.weekday, from: firstDay) - calendar.firstWeekday
        if firstWeekday < 0 {
            firstWeekday += 7
        }
        
        // Создаем массив дней для календаря
        var days: [[Date?]] = []
        
        // Создаем первую неделю с пустыми ячейками в начале
        var week: [Date?] = Array(repeating: nil, count: 7)
        
        // Заполняем первую неделю
        for day in 0..<min(7, numDays + firstWeekday) {
            if day >= firstWeekday {
                let dayOffset = day - firstWeekday
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: firstDay) {
                    week[day] = date
                }
            }
        }
        days.append(week)
        
        // Заполняем остальные недели
        let remainingDays = numDays - (7 - firstWeekday)
        let remainingWeeks = (remainingDays + 6) / 7 // Округление вверх
        
        for weekNum in 0..<remainingWeeks {
            week = Array(repeating: nil, count: 7)
            
            for dayOfWeek in 0..<7 {
                let day = 7 - firstWeekday + weekNum * 7 + dayOfWeek + 1
                if day <= numDays {
                    if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                        week[dayOfWeek] = date
                    }
                }
            }
            
            days.append(week)
        }
        
        calendarDays = days
    }
    
    private func findMonthIndex(for date: Date) -> Int? {
        let targetComponents = calendar.dateComponents([.year, .month], from: date)
        
        for (index, month) in months.enumerated() {
            let monthComponents = calendar.dateComponents([.year, .month], from: month)
            if monthComponents.year == targetComponents.year && monthComponents.month == targetComponents.month {
                return index
            }
        }
        
        return nil
    }
    
    private func findCurrentMonthIndex() {
        if let index = findMonthIndex(for: selectedDate) {
            currentMonthIndex = index
        } else if !months.isEmpty {
            // Если выбранная дата не найдена в месяцах, устанавливаем последний месяц
            currentMonthIndex = months.count - 1
        }
    }
    
    // Эти методы теперь вызываются напрямую из кнопок
    private func showPreviousMonth() {
        if currentMonthIndex > 0 {
            currentMonthIndex -= 1
        }
    }
    
    private func showNextMonth() {
        if currentMonthIndex < months.count - 1 && !isNextMonthDisabled {
            currentMonthIndex += 1
        }
    }
    
    // MARK: - Formatters
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
}
