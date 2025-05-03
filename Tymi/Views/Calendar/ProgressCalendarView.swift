import SwiftUI
import SwiftData

struct ProgressCalendarView: View {
    @Binding var selectedDate: Date
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    // Запрос всех привычек
    @Query private var habits: [Habit]
    
    // Настройки календаря
    private let calendar = Calendar.current
    private let maxPastMonths = 12
    private var minDate: Date {
        calendar.date(byAdding: .month, value: -maxPastMonths, to: Date()) ?? Date()
    }
    
    // Текущий месяц для отображения
    @State private var displayedMonth: Date = Date()
    @State private var tabIndex: Int = 12 // Начинаем с текущего месяца
    
    // Кэш прогресса для дат
    @State private var progressCache: [Date: Double] = [:]
    
    // Все доступные месяцы для табов
    private var allMonths: [Date] {
        var months: [Date] = []
        for i in -maxPastMonths...0 {
            if let date = calendar.date(byAdding: .month, value: i, to: Date()) {
                months.append(date)
            }
        }
        return months
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Заголовок месяца с кнопками навигации
            HStack {
                Button(action: {
                    if tabIndex > 0 {
                        withAnimation {
                            tabIndex -= 1
                            displayedMonth = allMonths[tabIndex]
                        }
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.primary)
                        .padding()
                        .contentShape(Rectangle())
                }
                .disabled(tabIndex <= 0)
                
                Spacer()
                
                Text(formattedMonthYear(displayedMonth))
                    .font(.title3.bold())
                
                Spacer()
                
                Button(action: {
                    if tabIndex < allMonths.count - 1 {
                        withAnimation {
                            tabIndex += 1
                            displayedMonth = allMonths[tabIndex]
                        }
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.primary)
                        .padding()
                        .contentShape(Rectangle())
                }
                .disabled(tabIndex >= allMonths.count - 1)
            }
            .padding(.horizontal)
            
            // Дни недели
            HStack(spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // TabView для плавной прокрутки месяцев
            TabView(selection: $tabIndex) {
                if tabIndex > 0 {
                    calendarGrid(for: allMonths[tabIndex - 1])
                        .tag(tabIndex - 1)
                }
                
                calendarGrid(for: allMonths[tabIndex])
                    .tag(tabIndex)
                
                if tabIndex < allMonths.count - 1 {
                    calendarGrid(for: allMonths[tabIndex + 1])
                        .tag(tabIndex + 1)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .onChange(of: tabIndex) { oldValue, newValue in
                withAnimation {
                    displayedMonth = allMonths[newValue]
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    updateProgressCache()
                }
            }
            
            // Кнопка "Сегодня"
            Button(action: {
                selectedDate = Date()
                let todayIndex = allMonths.count - 1 // Индекс текущего месяца
                withAnimation {
                    tabIndex = todayIndex
                    displayedMonth = allMonths[todayIndex]
                }
            }) {
                Text("today".localized)
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal)
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(.top, 20)
        .onAppear {
            updateProgressCache()
        }
        .onChange(of: displayedMonth) { _, _ in
            updateProgressCache()
        }
        .onChange(of: habits) { _, _ in
            updateProgressCache()
        }
    }
    
    // Создаем функцию для сетки календаря
    private func calendarGrid(for month: Date) -> some View {
        LazyVStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 10) {
                ForEach(daysInMonth(for: month)) { item in
                    if let date = item.date {
                        // Проверяем, является ли дата будущей
                        let isFutureDate = calendar.compare(date, to: Date(), toGranularity: .day) == .orderedDescending
                        
                        DayProgressCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            progress: progressCache[calendar.startOfDay(for: date)] ?? 0,
                            isCurrentMonth: calendar.isDate(date, equalTo: month, toGranularity: .month),
                            isDisabled: isFutureDate, // Отключаем будущие даты
                            onSelect: {
                                // Обработчик срабатывает только для не отключенных дат
                                if !isFutureDate {
                                    selectedDate = date
                                }
                            }
                        )
                    } else {
                        // Пустая ячейка для выравнивания сетки
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // Форматер для заголовка месяца
    private func formattedMonthYear(_ date: Date) -> String {
        return DateFormatter.monthYear.string(from: date)
    }
    
    // Символы дней недели
    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let firstWeekday = calendar.firstWeekday - 1
        return Array(symbols[firstWeekday...] + symbols[..<firstWeekday])
    }
    
    // Получение всех дат в указанном месяце для отображения
    private func daysInMonth(for month: Date) -> [DateGridItem] {
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let offsetInFirstRow = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var days = Array(0..<offsetInFirstRow).map { DateGridItem(date: nil, index: $0) }
        
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(DateGridItem(date: date, index: days.count))
            }
        }
        
        // Заполняем до конца последней недели
        let remainingCells = (7 - (days.count % 7)) % 7
        for i in 0..<remainingCells {
            days.append(DateGridItem(date: nil, index: days.count + i))
        }
        
        return days
    }
    
    private func updateProgressCache() {
        // Вычисляем даты только для видимого месяца и небольшого запаса
        guard let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else {
            return
        }
        
        // Получаем начало и конец месяца с запасом в несколько дней
        let monthStart = calendar.startOfMonth(for: displayedMonth)
        let monthEnd = calendar.endOfMonth(for: displayedMonth)
        
        // Добавляем неделю до и неделю после для плавной анимации
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: monthStart),
              let endDate = calendar.date(byAdding: .day, value: 7, to: monthEnd) else {
            return
        }
        
        // Используем для расчетов только те привычки, которые активны в этот период
        let relevantHabits = habits.filter { !$0.isFreezed }
        
        // Создаем временный кэш
        var newCache: [Date: Double] = [:]
        
        // Для каждого дня в диапазоне
        var currentDate = startDate
        while currentDate <= endDate {
            let dayStart = calendar.startOfDay(for: currentDate)
            
            // Рассчитываем прогресс только для активных привычек в этот день, учитывая startDate
            let activeHabits = relevantHabits.filter { habit in
                // Строгая проверка: привычка должна быть активна в этот день недели И дата должна быть >= startDate
                return currentDate >= habit.startDate && habit.isActiveOnDate(currentDate)
            }
            
            if !activeHabits.isEmpty {
                let totalPercentage = activeHabits.reduce(0.0) { sum, habit in
                    sum + habit.completionPercentageForDate(currentDate)
                }
                newCache[dayStart] = totalPercentage / Double(activeHabits.count)
            } else {
                // Важно: устанавливаем прогресс равным 0, чтобы не использовались старые значения
                newCache[dayStart] = 0
            }
            
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDay
            } else {
                break
            }
        }
        
        // Обновляем основной кэш
        DispatchQueue.main.async {
            progressCache = newCache
        }
    }

    // Эту функцию тоже нужно обновить для согласованности
    private func calculateDayProgress(for date: Date) -> Double {
        // Только привычки, которые не заморожены, активны в этот день недели, и дата >= startDate
        let activeHabits = habits.filter { habit in
            return !habit.isFreezed &&
            date >= habit.startDate &&
            habit.isActiveOnDate(date)
        }
        
        if activeHabits.isEmpty {
            return 0
        }
        
        let totalPercentage = activeHabits.reduce(0.0) { sum, habit in
            sum + habit.completionPercentageForDate(date)
        }
        
        return totalPercentage / Double(activeHabits.count)
    }
}
