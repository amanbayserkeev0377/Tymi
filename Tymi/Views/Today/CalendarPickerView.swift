import SwiftUI

struct CalendarPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private var days: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end)
        else { return [] }
        
        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        return calendar.generateDates(inside: dateInterval, matching: DateComponents(hour: 0, minute: 0, second: 0))
    }
    
    private var isDateSelectable: (Date) -> Bool {
        { date in
            let today = calendar.startOfDay(for: Date())
            return date <= today
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Text(monthFormatter.string(from: selectedDate))
                    .font(.headline)
                    .padding(.top)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { weekday in
                        Text(weekday)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    ForEach(days, id: \.self) { date in
                        if calendar.isDate(date, equalTo: selectedDate, toGranularity: .month) {
                            Button {
                                if isDateSelectable(date) {
                                    selectedDate = date
                                    dismiss()
                                }
                            } label: {
                                Text(dateFormatter.string(from: date))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        calendar.isDate(date, equalTo: selectedDate, toGranularity: .day)
                                        ? Color.accentColor
                                        : Color.clear
                                    )
                                    .clipShape(Circle())
                            }
                            .foregroundStyle(
                                isDateSelectable(date)
                                ? (calendar.isDate(date, equalTo: selectedDate, toGranularity: .day)
                                   ? Color.white
                                   : Color.primary)
                                : Color.secondary.opacity(0.5)
                            )
                        } else {
                            Text("")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private extension Calendar {
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