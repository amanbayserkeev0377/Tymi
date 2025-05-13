import SwiftUI
import SwiftData

struct WeeklyCalendarView: View {
    @Binding var selectedDate: Date
    @Environment(\.modelContext) private var modelContext
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    @AppStorage("firstDayOfWeek") private var firstDayOfWeek: Int = 0
    
    @Query private var habits: [Habit]
    
    @State private var weeks: [[Date]] = []
    @State private var currentWeekIndex: Int = 0
    @State private var progressData: [Date: Double] = [:]
    @State private var errorMessage: String?
    
    @State private var lastUpdateTime: TimeInterval = 0
    private let updateThreshold: TimeInterval = 0.5
    
    private let weekCount = 8
    
    private var calendar: Calendar {
        return Calendar.userPreferred
    }
    
    private var weekdaySymbols: [String] {
        return calendar.orderedFormattedWeekdaySymbols
    }
    
    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        
        let sortDescriptor = SortDescriptor<Habit>(\.createdAt, order: .forward)
        _habits = Query(sort: [sortDescriptor])
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ForEach(weekdaySymbols, id: \.self) { daySymbol in
                    Text(daySymbol)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 44)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
            
            TabView(selection: $currentWeekIndex) {
                ForEach(Array(weeks.enumerated()), id: \.element.first) { index, week in
                    HStack(spacing: 12) {
                        ForEach(week, id: \.self) { date in
                            DayProgressItem(
                                date: date,
                                isSelected: calendar.isDate(selectedDate, inSameDayAs: date),
                                progress: progressData[date] ?? 0,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedDate = date
                                    }
                                    
                                    habitsUpdateService.triggerUpdate()
                                }
                            )
                            .frame(width: 44)
                        }
                    }
                    .padding(.horizontal, 16)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 70)
            .onChange(of: currentWeekIndex) { _, _ in
                // Подгружаем данные о прогрессе при смене недели
                loadProgressData()
            }
        }
        .onAppear {
            generateWeeks()
            loadProgressData()
            findCurrentWeekIndex()
        }
        .onChange(of: selectedDate) { _, newDate in
            if let weekIndex = findWeekIndex(for: newDate) {
                withAnimation {
                    currentWeekIndex = weekIndex
                }
            }
            habitsUpdateService.triggerUpdate()
        }
        .onChange(of: habitsUpdateService.lastUpdateTimestamp) { _, _ in
            loadProgressData()
        }
        .onChange(of: firstDayOfWeek) { _, _ in
            // Перегенерируем недели при изменении первого дня недели
            weeks = []
            generateWeeks()
            findCurrentWeekIndex()
            loadProgressData()
        }
        .alert(errorMessage ?? "Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        }
    }
    
    private func generateWeeks() {
        let today = Date()
        let calendar = Calendar.userPreferred
        
        guard let currentWeekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        ) else {
            errorMessage = "Failed to generate calendar weeks"
            // Инициализируем пустой массив как резервный вариант
            weeks = []
            return
        }
        
        var generatedWeeks: [[Date]] = []
        
        for weekOffset in (1-weekCount)...0 {
            guard let weekStartDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: currentWeekStart) else {
                // Логирование ошибки, но продолжение цикла
                print("Не удалось создать дату начала недели для смещения \(weekOffset)")
                continue
            }
            
            var weekDates: [Date] = []
            
            for dayOffset in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate) {
                    weekDates.append(date)
                }
            }
            
            if !weekDates.isEmpty {
                generatedWeeks.append(weekDates)
            }
        }
        
        // Проверяем, что сгенерировали хоть какие-то недели
        if generatedWeeks.isEmpty {
            errorMessage = "Не удалось сгенерировать недели календаря"
        }
        
        weeks = generatedWeeks
    }
    
    private func loadProgressData() {
        // Проверяем, прошло ли достаточно времени с последнего обновления
        let now = Date().timeIntervalSince1970
        if now - lastUpdateTime < updateThreshold {
            return
        }
        
        lastUpdateTime = now
        
        // Обрабатываем только видимую неделю для производительности
        if !weeks.isEmpty {
            if currentWeekIndex < weeks.count {
                let week = weeks[currentWeekIndex]
                
                // Обновляем только даты до сегодня
                let now = Date()
                let relevantDates = week.filter { $0 <= now }
                
                for date in relevantDates {
                    let progress = calculateProgress(for: date)
                    progressData[date] = progress
                }
            }
            
            // Загружаем данные для сегодняшнего дня в любом случае
            let today = Date()
            let todayStart = calendar.startOfDay(for: today)
            progressData[todayStart] = calculateProgress(for: today)
        }
    }
    
    private func calculateProgress(for date: Date) -> Double {
        // Фильтруем привычки, которые активны в этот день
        let activeHabits = habits.filter { habit in
            habit.isActiveOnDate(date) && date >= habit.startDate
        }
        
        guard !activeHabits.isEmpty else { return 0 }
        
        // Вычисляем общий прогресс
        let totalProgress = activeHabits.reduce(0.0) { total, habit in
            let percentage = habit.completionPercentageForDate(date)
            return total + percentage
        }
        
        return totalProgress / Double(activeHabits.count)
    }
    
    private func findCurrentWeekIndex() {
        if let index = findWeekIndex(for: selectedDate) {
            withAnimation {
                currentWeekIndex = index
            }
        }
    }
    
    private func findWeekIndex(for date: Date) -> Int? {
        if weeks.isEmpty {
            return nil
        }
        
        for (index, week) in weeks.enumerated() {
            if week.contains(where: { calendar.isDate($0, inSameDayAs: date) }) {
                return index
            }
        }
        return nil
    }
}
