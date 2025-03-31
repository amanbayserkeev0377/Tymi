import SwiftUI

class CalendarViewModel: ObservableObject {
    @Published var selectedDate: Date
    @Published var currentMonth: Date
    @Published var daysWithHabits: Set<Date> = []
    @Published var completedHabits: Set<Date> = []
    @Published var partiallyCompletedHabits: Set<Date> = []
    
    private let calendar: Calendar = {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        return calendar
    }()
    
    init(selectedDate: Date = Date()) {
        self.selectedDate = selectedDate
        self.currentMonth = selectedDate
        // TODO: Загрузить дни с привычками из HabitStore
    }
    
    // Returns all dates for the calendar grid (including previous and next month)
    var dates: [Date] {
        let firstWeekday = calendar.component(.weekday, from: startOfMonth())
        let offsetDays = firstWeekday - 2 // 2 is Monday
        
        let startDate = calendar.date(byAdding: .day, value: -offsetDays, to: startOfMonth()) ?? startOfMonth()
        let endDate = calendar.date(byAdding: .day, value: 42, to: startDate) ?? endOfMonth() // 6 weeks * 7 days
        
        let interval = DateInterval(start: startDate, end: endDate)
        return calendar.generateDates(inside: interval, matching: DateComponents(hour: 0, minute: 0, second: 0, nanosecond: 0))
    }
    
    // Returns the formatted title of the current month
    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    // Navigates to the previous month
    func previousMonth() {
        withAnimation(.spring(response: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    // Navigates to the next month
    func nextMonth() {
        withAnimation(.spring(response: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
    
    // Checks if the given date is today
    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    // Checks if the given date is the selected date
    func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    // Checks if the given date is in the current month
    func isCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
    
    // Checks if the given date is in the future
    func isFuture(_ date: Date) -> Bool {
        date > Date()
    }
    
    // Returns the completion status for the given date
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
    
    // Returns the day component (1...31) for the given date
    func day(for date: Date) -> Int {
        calendar.component(.day, from: date)
    }
    
    // Returns the start date of the current month
    private func startOfMonth() -> Date {
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        return calendar.date(from: components) ?? currentMonth
    }
    
    // Returns the end of the current month
    private func endOfMonth() -> Date {
        let components = DateComponents(month: 1, day: -1)
        return calendar.date(byAdding: components, to: startOfMonth()) ?? currentMonth
    }
}

// Generates all dates that match the given components within a date interval
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

enum CompletionStatus {
    case none
    case hasHabits
    case partiallyCompleted
    case completed
}
