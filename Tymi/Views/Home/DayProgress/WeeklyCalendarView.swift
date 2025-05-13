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
    
    private let weekCount = 12
    
    private var calendar: Calendar {
        return Calendar.userPreferred
    }
    
    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        
        let sortDescriptor = SortDescriptor<Habit>(\.createdAt, order: .forward)
        _habits = Query(sort: [sortDescriptor])
    }
    
    var body: some View {
        // Убираем внешний VStack и названия дней недели
        TabView(selection: $currentWeekIndex) {
            ForEach(Array(weeks.enumerated()), id: \.element.first) { index, week in
                HStack(spacing: 16) { // Увеличиваем расстояние между днями
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
                        .frame(width: 35) // Увеличиваем ширину для более просторного отображения
                    }
                }
                .padding(.horizontal, 16)
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 55) // Уменьшаем высоту, так как убрали названия дней недели
        .onChange(of: currentWeekIndex) { _, _ in
            loadProgressData()
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
    
    // Остальные методы остаются без изменений
    private func generateWeeks() {
        let today = Date()
        let calendar = Calendar.userPreferred
        
        guard let currentWeekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        ) else {
            errorMessage = "failed_to_generate_calendar".localized
            weeks = []
            return
        }
        
        var generatedWeeks: [[Date]] = []
        
        for weekOffset in (1-weekCount)...0 {
            guard let weekStartDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: currentWeekStart) else {
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
        
        if generatedWeeks.isEmpty {
            print("ERROR: Failed to generate calendar weeks")
            weeks = []
        }
        
        weeks = generatedWeeks
    }
    
    // Улучшенная версия для загрузки прогресса
    private func loadProgressData() {
        if !weeks.isEmpty && currentWeekIndex < weeks.count {
            let week = weeks[currentWeekIndex]
            
            // Ограничиваем обработку только дней не позднее сегодняшнего
            let now = Date()
            let relevantDates = week.filter { $0 <= now }
            
            // Используем batch-обработку для улучшения производительности
            var newProgressData: [Date: Double] = [:]
            
            // Пакетно обрабатываем даты
            for date in relevantDates {
                let progress = calculateProgress(for: date)
                newProgressData[date] = progress
            }
            
            // Обновляем все значения сразу
            for (date, progress) in newProgressData {
                progressData[date] = progress
            }
        }
    }
    
    private func calculateProgress(for date: Date) -> Double {
        // Кэширование активных привычек для даты улучшает производительность
        let activeHabits = habits.filter { habit in
            habit.isActiveOnDate(date) && date >= habit.startDate
        }
        
        guard !activeHabits.isEmpty else { return 0 }
        
        // Вычисляем общий прогресс
        let totalCompletionPercentage = activeHabits.reduce(0.0) { total, habit in
            total + habit.completionPercentageForDate(date)
        }
        
        return totalCompletionPercentage / Double(activeHabits.count)
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
