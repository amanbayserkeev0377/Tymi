import SwiftUI
import Charts

struct WeeklyHabitChart: View {
    // MARK: - Properties
    let habit: Habit
    let updateCounter: Int // Add update counter parameter
    
    // MARK: - State
    @State private var weeks: [Date] = []
    @State private var currentWeekIndex: Int = 0
    @State private var chartData: [ChartDataPoint] = []
    @State private var selectedDate: Date?
    @State private var isLoading: Bool = false
    
    // MARK: - Calendar
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with navigation and stats
            headerView
            
            // Chart
            chartView
        }
        .onAppear {
            setupWeeks()
            findCurrentWeekIndex()  
            generateChartData()
        }
        .onChange(of: habit.goal) { _, _ in
            generateChartData()
        }
        .onChange(of: habit.activeDays) { _, _ in
            generateChartData()
        }
        .onChange(of: updateCounter) { _, _ in
            // React to external data changes (from calendar actions)
            generateChartData()
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            // Haptic feedback only when selection actually changes
            if let old = oldValue, let new = newValue, !calendar.isDate(old, inSameDayAs: new) {
                HapticManager.shared.playSelection()
            }
            // Or when first selecting (nil -> Date)
            else if oldValue == nil && newValue != nil {
                HapticManager.shared.playSelection()
            }
        }
    }
    
    // MARK: - Header View
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 12) {
            // Week range navigation with wider chevron touch areas
            HStack {
                Button(action: showPreviousWeek) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(canNavigateToPreviousWeek ? .primary : Color.gray.opacity(0.5))
                        .contentShape(Rectangle())
                        .frame(width: 44, height: 44) // Wider touch area
                }
                .disabled(!canNavigateToPreviousWeek)
                .buttonStyle(BorderlessButtonStyle())
                
                Spacer()
                
                Text(weekRangeString)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: showNextWeek) {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundStyle(canNavigateToNextWeek ? .primary : Color.gray.opacity(0.5))
                        .contentShape(Rectangle())
                        .frame(width: 44, height: 44) // Wider touch area
                }
                .disabled(!canNavigateToNextWeek)
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.horizontal, 8) // Smaller padding for navigation
            
            // Stats row - aligned exactly with chart bars
            HStack {
                // AVERAGE - align with left edge of first bar
                VStack(alignment: .leading, spacing: 2) {
                    if let selectedDate = selectedDate,
                       let selectedDataPoint = chartData.first(where: { calendar.isDate($0.date, inSameDayAs: selectedDate) }) {
                        Text("DAILY")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        Text(selectedDataPoint.formattedValueWithoutSeconds)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(AppColorManager.shared.selectedColor.color)
                        
                        Text(shortDateFormatter.string(from: selectedDataPoint.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("AVERAGE")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        Text(averageValueFormatted)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(AppColorManager.shared.selectedColor.color)
                        
                        Text("This Week")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // TOTAL - align with right edge of last bar
                VStack(alignment: .trailing, spacing: 2) {
                    Text("TOTAL")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    
                    Text(weeklyTotalFormatted)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColorManager.shared.selectedColor.color)
                    
                    Text("This Week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 0) // No padding - align with chart edges
        }
        // Remove extra padding from VStack - let individual rows control their own
    }
    
    // MARK: - Chart View
    @ViewBuilder
    private var chartView: some View {
        if isLoading {
            ProgressView()
                .frame(height: 200)
        } else {
            Chart(chartData) { dataPoint in
                BarMark(
                    x: .value("Day", dataPoint.date, unit: .day),
                    y: .value("Progress", dataPoint.value)
                )
                .foregroundStyle(barColor(for: dataPoint))
                .cornerRadius(4)
                .opacity(selectedDate == nil ? 1.0 : 
                        (calendar.isDate(dataPoint.date, inSameDayAs: selectedDate!) ? 1.0 : 0.4))
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: chartData.map { $0.date }) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                        .foregroundStyle(.gray.opacity(0.3))
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            let weekdayIndex = calendar.component(.weekday, from: date) - 1
                            let shortName = calendar.shortWeekdaySymbols[weekdayIndex]
                            Text(shortName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: yAxisValues) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                        .foregroundStyle(.gray.opacity(0.3))
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            if habit.type == .time {
                                Text(formatTimeWithoutSeconds(intValue))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(intValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .chartXSelection(value: $selectedDate)
            .gesture(dragGesture)
            .onTapGesture {
                if selectedDate != nil {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedDate = nil
                    }
                }
            }
            .id("week-\(currentWeekIndex)-\(updateCounter)")
        }
    }
    
    // MARK: - Computed Properties
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                let horizontalDistance = value.translation.width
                let verticalDistance = abs(value.translation.height)
                
                if abs(horizontalDistance) > verticalDistance * 2 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if horizontalDistance > 0 && canNavigateToPreviousWeek {
                            showPreviousWeek()
                        } else if horizontalDistance < 0 && canNavigateToNextWeek {
                            showNextWeek()
                        }
                    }
                }
            }
    }
    
    private var currentWeekStart: Date {
        guard !weeks.isEmpty && currentWeekIndex >= 0 && currentWeekIndex < weeks.count else {
            return Date()
        }
        return weeks[currentWeekIndex]
    }
    
    private var currentWeekEnd: Date {
        calendar.date(byAdding: .day, value: 6, to: currentWeekStart) ?? currentWeekStart
    }
    
    private var weekRangeString: String {
        let formatter = DateFormatter()
        
        if calendar.isDate(currentWeekStart, equalTo: currentWeekEnd, toGranularity: .month) {
            let startDay = calendar.component(.day, from: currentWeekStart)
            let endDay = calendar.component(.day, from: currentWeekEnd)
            formatter.dateFormat = "MMM yyyy"
            let monthYear = formatter.string(from: currentWeekStart)
            return "\(startDay)–\(endDay) \(monthYear)"
        } else {
            formatter.dateFormat = "d MMM"
            let startString = formatter.string(from: currentWeekStart)
            let endString = formatter.string(from: currentWeekEnd)
            formatter.dateFormat = "yyyy"
            let year = formatter.string(from: currentWeekEnd)
            return "\(startString)–\(endString) \(year)"
        }
    }
    
    private var averageValueFormatted: String {
        guard !chartData.isEmpty else { return "0" }
        
        let activeDaysData = chartData.filter { $0.value > 0 }
        guard !activeDaysData.isEmpty else { return "0" }
        
        let total = activeDaysData.reduce(0) { $0 + $1.value }
        let average = total / activeDaysData.count
        
        switch habit.type {
        case .count:
            return "\(average)"
        case .time:
            return formatTimeWithoutSeconds(average)
        }
    }
    
    private var weeklyTotalFormatted: String {
        guard !chartData.isEmpty else { return "0" }
        
        let total = chartData.reduce(0) { $0 + $1.value }
        
        switch habit.type {
        case .count:
            return "\(total)"
        case .time:
            return formatTimeWithoutSeconds(total)
        }
    }
    
    private var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }
    
    private func formatTimeWithoutSeconds(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%d min", minutes)
        } else {
            return "0"
        }
    }
    
    private var yAxisValues: [Int] {
        guard !chartData.isEmpty else { return [0] }
        
        let maxValue = chartData.map { $0.value }.max() ?? 0
        guard maxValue > 0 else { return [0] }
        
        let displayMaxValue = habit.type == .time ? maxValue / 3600 : maxValue
        let step = max(1, displayMaxValue / 3)
        
        let values = [0, step, step * 2, step * 3].filter { $0 <= displayMaxValue + step/2 }
        
        return habit.type == .time ? values.map { $0 * 3600 } : values
    }
    
    private var canNavigateToPreviousWeek: Bool {
        return currentWeekIndex > 0
    }
    
    private var canNavigateToNextWeek: Bool {
        guard !weeks.isEmpty else { return false }
        
        let today = Date()
        let todayWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        return currentWeekIndex < weeks.count - 1 && currentWeekStart < todayWeekStart
    }
    
    // MARK: - Navigation Methods
    
    private func showPreviousWeek() {
        guard canNavigateToPreviousWeek else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentWeekIndex -= 1
            selectedDate = nil
            generateChartData()
        }
    }
    
    private func showNextWeek() {
        guard canNavigateToNextWeek else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentWeekIndex += 1
            selectedDate = nil
            generateChartData()
        }
    }
    
    // MARK: - Bar Color
    
    private func barColor(for dataPoint: ChartDataPoint) -> Color {
        let date = dataPoint.date
        let value = dataPoint.value
        
        // Future dates or inactive days
        if !habit.isActiveOnDate(date) || date > Date() {
            return Color.gray.opacity(0.2)
        }
        
        // No progress
        if value == 0 {
            return Color.gray.opacity(0.3)
        }
        
        // Check completion status using ChartDataPoint's computed properties
        if dataPoint.isOverAchieved {
            // Over-achieved: Beautiful gradient green (darker for over-achievement)
            return Color(red: 0.0, green: 0.7, blue: 0.3) // Rich emerald green
        } else if dataPoint.isCompleted {
            // Completed: Success green with slight gradient feel
            return Color(red: 0.2, green: 0.8, blue: 0.4) // Bright success green
        } else {
            // Partial progress: Use user's selected color with reduced opacity
            return AppColorManager.shared.selectedColor.color.mix(with: .white, by: 0.1)
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupWeeks() {
        isLoading = true
        
        let today = Date()
        let todayWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        let effectiveStartDate = HistoryLimits.limitStartDate(habit.startDate)
        let habitStartWeekStart = calendar.dateInterval(of: .weekOfYear, for: effectiveStartDate)?.start ?? effectiveStartDate
        
        var weeksList: [Date] = []
        var currentWeek = habitStartWeekStart
        
        while currentWeek <= todayWeekStart {
            weeksList.append(currentWeek)
            currentWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeek) ?? currentWeek
        }
        
        weeks = weeksList
        isLoading = false
    }
    
    private func findCurrentWeekIndex() {
        let today = Date()
        let todayWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        if let index = weeks.firstIndex(where: { calendar.isDate($0, equalTo: todayWeekStart, toGranularity: .day) }) {
            currentWeekIndex = index
        } else {
            currentWeekIndex = max(0, weeks.count - 1)
        }
    }
    
    private func generateChartData() {
        guard !weeks.isEmpty && currentWeekIndex >= 0 && currentWeekIndex < weeks.count else {
            chartData = []
            return
        }
        
        let weekStart = currentWeekStart
        var data: [ChartDataPoint] = []
        
        for dayOffset in 0...6 {
            guard let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            
            let progress = habit.isActiveOnDate(currentDate) && currentDate >= habit.startDate && currentDate <= Date() 
                ? habit.progressForDate(currentDate) 
                : 0
            
            let dataPoint = ChartDataPoint(
                date: currentDate,
                value: progress,
                goal: habit.goal,
                habit: habit
            )
            
            data.append(dataPoint)
        }
        
        chartData = data
    }
}
