import SwiftUI
import SwiftData

struct MonthlyCalendarView: View {
    // MARK: - Properties
    let habit: Habit
    @Binding var selectedDate: Date
    
    // MARK: - State
    @State private var months: [Date] = []
    @State private var currentMonthIndex: Int = 0
    @State private var calendarDays: [[Date?]] = []
    @State private var isLoading: Bool = false
    @State private var progressCache: [Date: Double] = [:]
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    // MARK: - Initialization
    init(habit: Habit, selectedDate: Binding<Date>) {
        self.habit = habit
        self._selectedDate = selectedDate
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Месяц и навигация
            monthHeader
            
            // Дни недели
            weekdayHeader
            
            // Месячный календарь
            if isLoading {
                ProgressView()
                    .frame(height: 200)
            } else if months.isEmpty || calendarDays.isEmpty {
                // Отображаем сообщение, если данные не загружены
                Text("Загрузка календаря...")
                    .frame(height: 200)
            } else {
                TabView(selection: $currentMonthIndex) {
                    ForEach(Array(months.enumerated()), id: \.element) { index, month in
                        monthGrid(forMonth: month)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: min(CGFloat(calendarDays.count) * 50, 270))
                .onChange(of: currentMonthIndex) { _, _ in
                    generateCalendarDays()
                }
            }
        }
        .padding(.horizontal)
        .onAppear {
            isLoading = true
            DispatchQueue.main.async {
                generateMonths()
                findCurrentMonthIndex()
                generateCalendarDays()
                isLoading = false
            }
        }
        .onChange(of: selectedDate) { _, newDate in
            // Находим и устанавливаем индекс текущего месяца при изменении выбранной даты
            if let monthIndex = findMonthIndex(for: newDate) {
                currentMonthIndex = monthIndex
                generateCalendarDays()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .habitProgressUpdated)) { notification in
            // Проверяем, что уведомление относится к нашей привычке
            if let habitId = notification.object as? String,
               habitId == habit.id {
                // Обновляем кэш прогресса при изменении данных о прогрессе привычки
                updateProgressCache()
            }
        }
    }
    
    // MARK: - Components
    
    private var monthHeader: some View {
        HStack {
            Button(action: showPreviousMonth) {
                Image(systemName: "chevron.left")
                    .foregroundColor(currentMonthIndex > 0 ? .blue : .gray)
            }
            .disabled(currentMonthIndex <= 0)
            
            Spacer()
            
            Text(monthYearFormatter.string(from: currentMonth))
                .font(.headline)
                .fontWeight(.bold)
            
            Spacer()
            
            Button(action: showNextMonth) {
                Image(systemName: "chevron.right")
                    .foregroundColor(isNextMonthDisabled ? .gray : .blue)
            }
            .disabled(isNextMonthDisabled)
        }
    }
    
    private var weekdayHeader: some View {
        HStack {
            ForEach(0..<7, id: \.self) { index in
                Text(calendar.orderedWeekdayInitials[index])
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func monthGrid(forMonth month: Date) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
            ForEach(0..<calendarDays.count, id: \.self) { row in
                ForEach(0..<7, id: \.self) { column in
                    if let date = calendarDays[row][column] {
                        DayProgressItem(
                            date: date,
                            isSelected: calendar.isDate(selectedDate, inSameDayAs: date),
                            progress: progressCache[date] ?? 0,
                            onTap: {
                                selectedDate = date
                            }
                        )
                        .contextMenu {
                            Button {
                                print("Complete tapped for \(date)")
                                // Здесь вызвать нужный callback или действие
                            } label: {
                                Label("Complete", systemImage: "checkmark")
                            }
                            Button {
                                print("Add Progress tapped for \(date)")
                                // Здесь вызвать нужный callback или действие
                            } label: {
                                Label("Add Progress", systemImage: "plus")
                            }
                        }
                        .frame(width: 35, height: 40)
                        .id("\(row)-\(column)") // Добавляем уникальный id для каждой ячейки
                    } else {
                        Color.clear
                            .frame(width: 35, height: 40)
                            .id("\(row)-\(column)-empty") // Уникальный id для пустых ячеек
                    }
                }
            }
        }
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
        let startDate = habit.startDate
        let today = Date()
        
        // Создаем массив дат для месяцев
        var dateComponents = calendar.dateComponents([.year, .month], from: startDate)
        let startMonth = calendar.date(from: dateComponents)!
        
        dateComponents = calendar.dateComponents([.year, .month], from: today)
        let currentMonth = calendar.date(from: dateComponents)!
        
        var month = startMonth
        var generatedMonths: [Date] = []
        
        // Генерируем месяцы от начала привычки до текущего месяца
        while month <= currentMonth {
            generatedMonths.append(month)
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: month) else { break }
            month = nextMonth
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
        
        // Обновляем кэш прогресса для всех дат в календаре
        updateProgressCache()
    }
    
    private func updateProgressCache() {
        // Очищаем текущий кэш перед обновлением
        progressCache.removeAll()
        
        // Собираем все даты из календаря
        var allDates: [Date] = []
        for week in calendarDays {
            for day in week {
                if let date = day {
                    allDates.append(date)
                }
            }
        }
        
        // Обновляем прогресс для всех дат
        for date in allDates {
            // Проверяем активность дня и принадлежность к диапазону
            if date <= Date() && date >= habit.startDate && habit.isActiveOnDate(date) {
                progressCache[date] = habit.completionPercentageForDate(date)
            } else {
                progressCache[date] = 0
            }
        }
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
    
    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}

// MARK: - Extension for Swipe Gesture

extension View {
    func onSwipe(to direction: SwipeDirection, perform action: @escaping () -> Void) -> some View {
        self.gesture(DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onEnded { value in
                switch direction {
                case .leading where value.translation.width < 0:
                    action()
                case .trailing where value.translation.width > 0:
                    action()
                default:
                    break
                }
            }
        )
    }
}

// MARK: - SwipeDirection

enum SwipeDirection {
    case leading
    case trailing
}
