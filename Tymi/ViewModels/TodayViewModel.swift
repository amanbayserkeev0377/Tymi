import Foundation
import SwiftUI

@MainActor
final class TodayViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var weekDates: [Date] = []
    @Published private(set) var selectedDate: Date = Date()
    @Published var currentWeekDates: [Date] = []
    @Published var daysWithHabits: Set<Date> = []
    @Published var completedHabits: Set<Date> = []
    @Published var partiallyCompletedHabits: Set<Date> = []
    
    // MARK: - Private Properties
    private let calendar = Calendar.current
    private let maxPastWeeks = 2 // Максимальное количество недель в прошлое
    
    // MARK: - Initialization
    init() {
        updateWeekDates()
        updateProgress()
    }
    
    // MARK: - Public Methods
    private func updateWeekDates() {
        let today = calendar.startOfDay(for: Date())
        weekDates = datesForWeek(containing: today)
        selectedDate = today
    }
    
    private func datesForWeek(containing date: Date) -> [Date] {
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) else {
            return []
        }
        
        return (0...6).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: weekStart)
        }
    }
    
    func moveToNextWeek() {
        guard let firstDate = weekDates.first,
              let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: firstDate)
        else { return }
        
        weekDates = datesForWeek(containing: nextWeekStart)
    }
    
    func moveToPreviousWeek() {
        guard let firstDate = weekDates.first,
              let previousWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: firstDate),
              isDateWithinAllowedRange(previousWeekStart)
        else { return }
        
        weekDates = datesForWeek(containing: previousWeekStart)
    }
    
    func selectDate(_ date: Date) {
        guard isDateSelectable(date) else { return }
        selectedDate = date
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
    
    func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    private func isDateWithinAllowedRange(_ date: Date) -> Bool {
        let today = calendar.startOfDay(for: Date())
        guard let maxPastDate = calendar.date(byAdding: .weekOfYear, value: -maxPastWeeks, to: today) else {
            return false
        }
        return date >= maxPastDate
    }
    
    private func isDateSelectable(_ date: Date) -> Bool {
        let today = calendar.startOfDay(for: Date())
        return date <= today && isDateWithinAllowedRange(date)
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