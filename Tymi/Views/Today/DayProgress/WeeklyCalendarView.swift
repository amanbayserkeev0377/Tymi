import SwiftUI
import SwiftData

struct WeeklyCalendarView: View {
    @Binding var selectedDate: Date
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var habitsUpdateService: HabitsUpdateService
    
    @Query private var habits: [Habit]
    
    @State private var weeks: [[Date]] = []
    @State private var currentWeekIndex: Int = 0
    @State private var progressData: [Date: Double] = [:]
    
    private let calendar = Calendar.current
    private let weekCount = 8
    
    private var weekdaySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols
        
        let formattedSymbols = symbols.map { symbol in
            if symbol.count > 0 {
                return symbol.prefix(1).uppercased() + symbol.dropFirst().lowercased()
            }
            return symbol
        }
        
        let firstWeekday = calendar.firstWeekday - 1
        let before = Array(formattedSymbols[firstWeekday...])
        let after = Array(formattedSymbols[..<firstWeekday])
        return before + after
    }
    
    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        
        let predicate = #Predicate<Habit> { !$0.isFreezed }
        let sortDescriptor = SortDescriptor<Habit>(\.createdAt, order: .forward)
        _habits = Query(filter: predicate, sort: [sortDescriptor])
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
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 70)
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
        }
        .onChange(of: habitsUpdateService.lastUpdateTimestamp) { _, _ in
            loadProgressData()
        }
    }
    
    private func generateWeeks() {
        let today = Date()
        var generatedWeeks: [[Date]] = []
        
        guard let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return
        }
        
        for weekOffset in (1-weekCount)...0 {
            if let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: currentWeekStart) {
                var weekDates: [Date] = []
                
                for dayOffset in 0..<7 {
                    if let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                        weekDates.append(date)
                    }
                }
                
                generatedWeeks.append(weekDates)
            }
        }
        
        weeks = generatedWeeks
    }
    
    private func loadProgressData() {
        Task {
            for week in weeks {
                for date in week {
                    if date <= Date() {
                        let progress = await calculateProgress(for: date)
                        
                        await MainActor.run {
                            progressData[date] = progress
                        }
                    }
                }
            }
        }
    }
    
    private func calculateProgress(for date: Date) async -> Double {
        let activeHabits = habits.filter { habit in
            habit.isActiveOnDate(date) && date >= habit.startDate
        }
        
        guard !activeHabits.isEmpty else { return 0 }
        
        let totalProgress = activeHabits.reduce(0.0) { total, habit in
            let percentage = habit.completionPercentageForDate(date)
            return total + percentage
        }
        
        return totalProgress / Double(activeHabits.count)
    }
    
    private func findCurrentWeekIndex() {
        if let index = findWeekIndex(for: selectedDate) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    currentWeekIndex = index
                }
            }
        }
    }
    
    private func findWeekIndex(for date: Date) -> Int? {
        for (index, week) in weeks.enumerated() {
            if week.contains(where: { calendar.isDate($0, inSameDayAs: date) }) {
                return index
            }
        }
        return nil
    }
}
