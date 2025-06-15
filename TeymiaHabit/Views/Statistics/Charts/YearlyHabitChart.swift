import SwiftUI
import Charts

struct YearlyHabitChart: View {
    // MARK: - Properties
    let habit: Habit
    let updateCounter: Int
    
    // MARK: - State
    @State private var years: [Date] = []
    @State private var currentYearIndex: Int = 0
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
            setupYears()
            findCurrentYearIndex()
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
            // Haptic feedback only when selection actually changes (for months use month granularity)
            if let old = oldValue, let new = newValue, !calendar.isDate(old, equalTo: new, toGranularity: .month) {
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
            // Year range navigation with wider chevron touch areas
            HStack {
                Button(action: showPreviousYear) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(canNavigateToPreviousYear ? .primary : Color.gray.opacity(0.5))
                        .contentShape(Rectangle())
                        .frame(width: 44, height: 44) // Wider touch area
                }
                .disabled(!canNavigateToPreviousYear)
                .buttonStyle(BorderlessButtonStyle())
                
                Spacer()
                
                Text(yearRangeString)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: showNextYear) {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundStyle(canNavigateToNextYear ? .primary : Color.gray.opacity(0.5))
                        .contentShape(Rectangle())
                        .frame(width: 44, height: 44) // Wider touch area
                }
                .disabled(!canNavigateToNextYear)
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.horizontal, 8) // Smaller padding for navigation
            
            // Stats row - aligned exactly with chart bars
            HStack {
                // AVERAGE - align with left edge of first bar
                VStack(alignment: .leading, spacing: 2) {
                    if let selectedDate = selectedDate,
                       let selectedDataPoint = chartData.first(where: { 
                           calendar.isDate($0.date, equalTo: selectedDate, toGranularity: .month)
                       }) {
                        Text("MONTHLY")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        Text(selectedDataPoint.formattedValueWithoutSeconds)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(AppColorManager.shared.selectedColor.color)
                        
                        Text(monthYearFormatter.string(from: selectedDataPoint.date).capitalized)
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
                        
                        Text("This Year")
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
                    
                    Text(yearlyTotalFormatted)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColorManager.shared.selectedColor.color)
                    
                    Text("This Year")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 0) // No padding - align with chart edges
        }
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
                    x: .value("Month", dataPoint.date, unit: .month),
                    y: .value("Progress", dataPoint.value)
                )
                .foregroundStyle(barColor(for: dataPoint))
                .cornerRadius(3)
                .opacity(selectedDate == nil ? 1.0 : 
                        (calendar.component(.month, from: dataPoint.date) == calendar.component(.month, from: selectedDate!) &&
                         calendar.component(.year, from: dataPoint.date) == calendar.component(.year, from: selectedDate!) ? 1.0 : 0.4))
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: xAxisValues) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                        .foregroundStyle(.gray.opacity(0.3))
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(firstLetterOfMonth(from: date))
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
            .id("year-\(currentYearIndex)-\(updateCounter)")
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
                        if horizontalDistance > 0 && canNavigateToPreviousYear {
                            showPreviousYear()
                        } else if horizontalDistance < 0 && canNavigateToNextYear {
                            showNextYear()
                        }
                    }
                }
            }
    }
        
    private var currentYear: Date {
        guard !years.isEmpty && currentYearIndex >= 0 && currentYearIndex < years.count else {
            return Date()
        }
        return years[currentYearIndex]
    }
    
    private var yearRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: currentYear)
    }
    
    private var averageValueFormatted: String {
        guard !chartData.isEmpty else { return "0" }
        
        let activeMonthsData = chartData.filter { $0.value > 0 }
        guard !activeMonthsData.isEmpty else { return "0" }
        
        let total = activeMonthsData.reduce(0) { $0 + $1.value }
        let average = total / activeMonthsData.count
        
        switch habit.type {
        case .count:
            return "\(average)"
        case .time:
            return formatTimeWithoutSeconds(average)
        }
    }
    
    private var yearlyTotalFormatted: String {
        guard !chartData.isEmpty else { return "0" }
        
        let total = chartData.reduce(0) { $0 + $1.value }
        
        switch habit.type {
        case .count:
            return "\(total)"
        case .time:
            return formatTimeWithoutSeconds(total)
        }
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL"
        return formatter
    }
    
    private var shortMonthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }
    
    private func firstLetterOfMonth(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let monthName = formatter.string(from: date)
        return String(monthName.prefix(1)).uppercased()
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
    
    // X-axis values - show every month for the year
    private var xAxisValues: [Date] {
        return chartData.map { $0.date }
    }
    
    private var canNavigateToPreviousYear: Bool {
        return currentYearIndex > 0
    }
    
    private var canNavigateToNextYear: Bool {
        guard !years.isEmpty else { return false }
        
        let today = Date()
        let currentYearComponents = calendar.dateComponents([.year], from: today)
        let displayedYearComponents = calendar.dateComponents([.year], from: currentYear)
        
        return displayedYearComponents.year! < currentYearComponents.year!
    }
    
    // MARK: - Navigation Methods
    
    private func showPreviousYear() {
        guard canNavigateToPreviousYear else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentYearIndex -= 1
            selectedDate = nil
            generateChartData()
        }
    }
    
    private func showNextYear() {
        guard canNavigateToNextYear else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentYearIndex += 1
            selectedDate = nil
            generateChartData()
        }
    }
    
    // MARK: - Bar Color
    
    private func barColor(for dataPoint: ChartDataPoint) -> Color {
        let value = dataPoint.value
        
        // No progress
        if value == 0 {
            return Color.gray.opacity(0.3)
        }
        
        // For yearly view, we calculate monthly averages against daily goal
        // So we use different logic than daily completion
        let monthlyAverage = value > 0 ? value : 0
        let dailyGoal = habit.goal
        
        // Rough calculation: if monthly total suggests good daily performance
        let estimatedDailyAverage = Double(monthlyAverage) / 30.0 // rough daily average for month
        let dailyGoalDouble = Double(dailyGoal)
        
        if estimatedDailyAverage >= dailyGoalDouble {
            // Good performance: Success green
            return Color(red: 0.2, green: 0.8, blue: 0.4)
        } else if estimatedDailyAverage >= dailyGoalDouble * 0.7 {
            // Decent performance: User's color 
            return AppColorManager.shared.selectedColor.color.mix(with: .white, by: 0.1)
        } else {
            // Low performance: Muted user color
            return AppColorManager.shared.selectedColor.color.mix(with: .white, by: 0.4)
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupYears() {
        isLoading = true
        
        let today = Date()
        let currentYearComponents = calendar.dateComponents([.year], from: today)
        let currentYear = calendar.date(from: currentYearComponents) ?? today
        
        let effectiveStartDate = HistoryLimits.limitStartDate(habit.startDate)
        let habitStartComponents = calendar.dateComponents([.year], from: effectiveStartDate)
        let habitStartYear = calendar.date(from: habitStartComponents) ?? effectiveStartDate
        
        var yearsList: [Date] = []
        var currentYearDate = habitStartYear
        
        while currentYearDate <= currentYear {
            yearsList.append(currentYearDate)
            currentYearDate = calendar.date(byAdding: .year, value: 1, to: currentYearDate) ?? currentYearDate
        }
        
        years = yearsList
        isLoading = false
    }
    
    private func findCurrentYearIndex() {
        let today = Date()
        let currentYearComponents = calendar.dateComponents([.year], from: today)
        let currentYear = calendar.date(from: currentYearComponents) ?? today
        
        if let index = years.firstIndex(where: { calendar.isDate($0, equalTo: currentYear, toGranularity: .year) }) {
            currentYearIndex = index
        } else {
            currentYearIndex = max(0, years.count - 1)
        }
    }
    
    private func generateChartData() {
        guard !years.isEmpty && currentYearIndex >= 0 && currentYearIndex < years.count else {
            chartData = []
            return
        }
        
        let year = currentYear
        var data: [ChartDataPoint] = []
        
        // Generate data for each month in the year (12 months)
        for month in 1...12 {
            guard let monthDate = calendar.date(byAdding: .month, value: month - 1, to: year) else { continue }
            
            // Calculate total progress for this month
            let monthProgress = calculateMonthlyProgress(for: monthDate)
            
            let dataPoint = ChartDataPoint(
                date: monthDate,
                value: monthProgress,
                goal: habit.goal, // Daily goal for reference
                habit: habit
            )
            
            data.append(dataPoint)
        }
        
        chartData = data
    }
    
    private func calculateMonthlyProgress(for monthDate: Date) -> Int {
        // Get the range of days in this month
        guard let range = calendar.range(of: .day, in: .month, for: monthDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)) else {
            return 0
        }
        
        var totalProgress = 0
        
        // Sum up progress for each day in the month
        for day in 1...range.count {
            guard let currentDate = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) else { continue }
            
            // Only count days that are within habit range and not in future
            if habit.isActiveOnDate(currentDate) && currentDate >= habit.startDate && currentDate <= Date() {
                totalProgress += habit.progressForDate(currentDate)
            }
        }
        
        return totalProgress
    }
}
