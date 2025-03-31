import SwiftUI

class CalendarViewModel: ObservableObject {
    @Published var selectedDate: Date
    @Published var currentMonth: Date
    
    private let calendar: Calendar = {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        return calendar
    }()
    
    init(selectedDate: Date = Date()) {
        self.selectedDate = selectedDate
        self.currentMonth = selectedDate
    }
    
    // Returns all dates withing the current month
    var dates: [Date] {
        let interval = DateInterval(start: startOfMonth(), end: endOfMonth())
        return calendar.generateDates(inside: interval, matching: DateComponents(day: 1, hour: 0, minute: 0, second: 0, nanosecond: 0))
    }
    
    // Returns the formatted title of the current month
    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    // Navigates to the previous month
    func previousMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    // Navigates to the next month
    func nextMonth() {
        withAnimation {
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
    
    // Returns the weekday index for the given date
    func weekday(for date: Date) -> Int {
        calendar.component(.weekday, from: date)
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
