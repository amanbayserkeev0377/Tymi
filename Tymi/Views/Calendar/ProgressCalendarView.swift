import SwiftUI
import SwiftData

struct ProgressCalendarView: View {
    // MARK: - Dependencies
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    
    // MARK: - State
    @State private var selectedDate: Date = .now
    @State private var progressData: [Date: Double] = [:]
    @State private var isLoading = false
    
    // MARK: - Constants
    private let calendar = Calendar.current
    private let dateRange: ClosedRange<Date>
    
    // MARK: - Initialization
    init(dateRange: ClosedRange<Date>) {
        self.dateRange = dateRange
        let predicate = #Predicate<Habit> { habit in
            !habit.isFreezed && habit.startDate <= dateRange.upperBound
        }
        let sortDescriptor = SortDescriptor<Habit>(\.createdAt, order: .forward)
        _habits = Query(filter: predicate, sort: [sortDescriptor])
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 16) {
            // Calendar Header
            HStack {
                Text(selectedDate.formatted(.dateTime.month().year()))
                    .font(.headline)
                Spacer()
                Button(action: { selectedDate = .now }) {
                    Text("Today")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal)
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(calendar.daysInMonth(for: selectedDate), id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        progress: progressData[date] ?? 0,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal)
            
            // Progress Details
            if let progress = progressData[selectedDate] {
                ProgressDetailsView(progress: progress)
            }
        }
        .task {
            await loadProgressData()
        }
        .onChange(of: selectedDate) { _, _ in
            Task {
                await loadProgressData()
            }
        }
        .onChange(of: habits) { _, _ in
            Task {
                await loadProgressData()
            }
        }
    }
    
    // MARK: - Private Methods
    private func loadProgressData() async {
        guard !isLoading else { return }
        isLoading = true
        
        let dates = calendar.datesInRange(dateRange)
        var newProgressData: [Date: Double] = [:]
        
        for date in dates {
            let progress = await calculateProgress(for: date)
            newProgressData[date] = progress
        }
        
        await MainActor.run {
            progressData = newProgressData
            isLoading = false
        }
    }
    
    private func calculateProgress(for date: Date) async -> Double {
        let activeHabits = habits.filter { habit in
            habit.isActiveOnDate(date)
        }
        
        guard !activeHabits.isEmpty else { return 0 }
        
        let totalProgress = activeHabits.reduce(0.0) { total, habit in
            let completion = Double(habit.progressForDate(date))
            return total + completion
        }
        
        return totalProgress / Double(activeHabits.count)
    }
}

// MARK: - Supporting Views
private struct CalendarDayView: View {
    let date: Date
    let progress: Double
    let isSelected: Bool
    
    var body: some View {
        VStack {
            Text(date.formatted(.dateTime.day()))
                .font(.caption)
                .foregroundColor(isSelected ? .white : .primary)
            
            Circle()
                .fill(progressColor)
                .frame(width: 8, height: 8)
        }
        .frame(height: 40)
        .background(isSelected ? Color.accentColor : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var progressColor: Color {
        switch progress {
        case 0: return .gray
        case 0..<0.5: return .red
        case 0.5..<0.8: return .yellow
        default: return .green
        }
    }
}

private struct ProgressDetailsView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Daily Progress")
                .font(.headline)
            
            ProgressView(value: progress)
                .progressViewStyle(.linear)
            
            Text(String(format: "%.0f%%", progress * 100))
                .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
}

// MARK: - Calendar Extensions
private extension Calendar {
    func daysInMonth(for date: Date) -> [Date] {
        guard let monthInterval = dateInterval(of: .month, for: date),
              let monthFirstWeek = dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = dateInterval(of: .weekOfMonth, for: monthInterval.end - 1) else {
            return []
        }
        
        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        return generateDates(for: dateInterval, matching: DateComponents(day: 1))
    }
    
    func datesInRange(_ range: ClosedRange<Date>) -> [Date] {
        generateDates(for: DateInterval(start: range.lowerBound, end: range.upperBound), matching: DateComponents(day: 1))
    }
    
    private func generateDates(for dateInterval: DateInterval, matching components: DateComponents) -> [Date] {
        var dates: [Date] = []
        dates.reserveCapacity(32)
        
        enumerateDates(startingAfter: dateInterval.start - 1,
                      matching: components,
                      matchingPolicy: .nextTime) { date, _, stop in
            if let date = date {
                if date <= dateInterval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }
        
        return dates
    }
}
