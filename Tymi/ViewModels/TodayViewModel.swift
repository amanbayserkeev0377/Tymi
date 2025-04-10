import Foundation
import SwiftUI

@MainActor
final class TodayViewModel: ObservableObject {
    // MARK: - Published Properties
    @AppStorage("firstWeekday") private var firstWeekday: Int = Calendar.current.firstWeekday
    @Published var selectedDate: Date = Date()
    @Published var currentWeekDates: [Date] = []
    @Published var daysWithHabits: Set<Date> = []
    @Published var completedHabits: Set<Date> = []
    @Published var partiallyCompletedHabits: Set<Date> = []
    
    // MARK: - Private Properties
    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = firstWeekday
        return calendar
    }
    
    private let habitStore: HabitStoreManager
    private let maxPastWeeks = 2 // Максимальное количество недель в прошлое
    
    // MARK: - Initialization
    init(habitStore: HabitStoreManager = HabitStoreManager()) {
        self.habitStore = habitStore
        updateWeekDates()
        updateProgress()
    }
    
    // MARK: - Public Methods
    func datesForWeek(offset: Int) -> [Date] {
        let today = Date()
        
        // Получаем начало текущей недели
        guard let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return []
        }
        
        // Вычисляем начало нужной недели (только в прошлое)
        guard let targetWeekStart = calendar.date(byAdding: .weekOfYear, value: -abs(offset), to: currentWeekStart) else {
            return []
        }
        
        // Генерируем даты для недели
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: targetWeekStart)
        }
    }
    
    func moveToWeek(offset: Int) {
        // Проверяем, не пытаемся ли мы перейти в будущее или слишком далеко в прошлое
        if offset > 0 || abs(offset) > maxPastWeeks {
            return
        }
        
        let dates = datesForWeek(offset: offset)
        guard !dates.isEmpty else { return }
        
        currentWeekDates = dates
        
        // Если текущая выбранная дата не в новой неделе, выбираем первый доступный день
        if !dates.contains(where: { calendar.isDate($0, inSameDayAs: selectedDate) }) {
            for date in dates {
                if isDateSelectable(date) {
                    selectedDate = date
                    break
                }
            }
        }
        
        updateProgress()
    }
    
    func updateWeekDates() {
        currentWeekDates = datesForWeek(offset: 0)
    }
    
    func updateProgress() {
        let habits = habitStore.habits
        var daysWithHabits = Set<Date>()
        var completedHabits = Set<Date>()
        var partiallyCompletedHabits = Set<Date>()
        
        for habit in habits {
            let progress = habitStore.getAllProgress(for: habit)
            
            for habitProgress in progress {
                let date = calendar.startOfDay(for: habitProgress.date)
                daysWithHabits.insert(date)
                
                if habitProgress.isCompleted {
                    completedHabits.insert(date)
                } else if habitProgress.value > 0 {
                    partiallyCompletedHabits.insert(date)
                }
            }
        }
        
        self.daysWithHabits = daysWithHabits
        self.completedHabits = completedHabits
        self.partiallyCompletedHabits = partiallyCompletedHabits
    }
    
    func moveToNextWeek() {
        guard let nextWeek = calendar.date(byAdding: .day, value: 7, to: currentWeekDates[0]) else {
            return
        }
        currentWeekDates = (0...6).map { day in
            calendar.date(byAdding: .day, value: day, to: nextWeek) ?? nextWeek
        }
    }
    
    func moveToPreviousWeek() {
        guard let previousWeek = calendar.date(byAdding: .day, value: -7, to: currentWeekDates[0]) else {
            return
        }
        
        // Проверяем, не превышает ли предыдущая неделя максимальное количество дней в прошлом
        let daysFromToday = calendar.dateComponents([.day], from: previousWeek, to: Date()).day ?? 0
        if daysFromToday > maxPastWeeks * 7 {
            return
        }
        
        currentWeekDates = (0...6).map { day in
            calendar.date(byAdding: .day, value: day, to: previousWeek) ?? previousWeek
        }
    }
    
    func selectDate(_ date: Date) {
        if isDateSelectable(date) {
            selectedDate = date
        }
    }
    
    func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    func isDateSelectable(_ date: Date) -> Bool {
        // Дата не должна быть в будущем
        if calendar.compare(date, to: Date(), toGranularity: .day) == .orderedDescending {
            return false
        }
        
        // Проверяем, не слишком ли далеко в прошлом
        let weeksFromToday = calendar.dateComponents([.weekOfYear], from: date, to: Date()).weekOfYear ?? 0
        return weeksFromToday <= maxPastWeeks
    }
    
    func completionStatus(for date: Date) -> CompletionStatus {
        let startOfDay = calendar.startOfDay(for: date)
        if completedHabits.contains(startOfDay) {
            return .completed
        } else if partiallyCompletedHabits.contains(startOfDay) {
            return .partiallyCompleted
        } else if daysWithHabits.contains(startOfDay) {
            return .hasHabits
        } else {
            return .none
        }
    }
    
    // MARK: - Formatting Methods
    func formattedMonthYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    func formattedFullDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: selectedDate)
    }
    
    func weekdaySymbol(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

// MARK: - Completion Status
enum CompletionStatus {
    case none
    case hasHabits
    case partiallyCompleted
    case completed
}

// MARK: - Calendar Extension
extension Calendar {
    func generateDates(inside interval: DateInterval, matching components: DateComponents) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)
        
        enumerateDates(
            startingAfter: interval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date < interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }
        return dates
    }
} 