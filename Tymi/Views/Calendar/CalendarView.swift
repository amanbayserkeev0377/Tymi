import SwiftUI
import SwiftData

struct CalendarView: View {
    @Binding var selectedDate: Date
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    private let maxPastMonths = 12
    private let maxFutureDay = 0
    
    private var minDate: Date {
        Calendar.current.date(byAdding: .month, value: -maxPastMonths, to: Date()) ?? Date()
    }
    
    private var maxDate: Date {
        Calendar.current.date(byAdding: .day, value: maxFutureDay, to: Date()) ?? Date()
    }
    
    var body: some View {
        ProgressCalendarView(selectedDate: $selectedDate)
            .padding(.bottom, 16)
    }
}
