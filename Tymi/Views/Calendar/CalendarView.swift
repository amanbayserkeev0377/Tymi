import SwiftUI
import SwiftData

struct CalendarView: View {
    @Binding var selectedDate: Date
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    private let calendar = Calendar.current
    private let maxPastMonths = 12
    
    private var minDate: Date {
        calendar.date(byAdding: .month, value: -maxPastMonths, to: Date()) ?? Date()
    }
    
    private var maxDate: Date {
        Date()
    }
    
    var body: some View {
        VStack {
            ProgressCalendarView(dateRange: minDate...maxDate)
        }
    }
}
