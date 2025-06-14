import SwiftUI
import Charts

struct WeeklyHabitChart: View {
    // MARK: - Properties
    let habit: Habit
    
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
    }
    
    // MARK: - Header View
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 12) {
            // Week range navigation
            HStack {
                Button(action: showPreviousWeek) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(canNavigateToPreviousWeek ? .primary : Color.gray.opacity(0.5))
                        .contentShape(Rectangle())
                        .frame(width: 30, height: 30)
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
                        .frame(width: 30, height: 30)
                }
                .disabled(!canNavigateToNextWeek)
                .buttonStyle(BorderlessButtonStyle())
            }
            
            // Stats row
            HStack {
                // AVERAGE
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
                
                Spacer()
                
                // TOTAL
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
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Chart View
    @ViewBuilder
    private var chartView: some View {
        if isLoading {
            ProgressView()
                .frame(height: 200)
        } else if chartData.isEmpty {
            ContentUnavailableView(
                "No Data",
                systemImage: "chart.bar",
                description: Text("No progress recorded for this week")
            )
            .frame(height: 200)
        } else {
            Chart(chartData) { dataPoint in
                BarMark(
                    x: .value("Day", dataPoint.date, unit: .day),
                    y: .value("Progress", dataPoint.value)
                )
                .foregroundStyle(barColor(for: dataPoint))
                .cornerRadius(4) // Более современные углы
                .opacity(selectedDate == nil ? 1.0 : 
                        (calendar.isDate(dataPoint.date, inSameDayAs: selectedDate!) ? 1.0 : 0.4))
            }
            .frame(height: 200)
            .chartPlotStyle { plotArea in
                plotArea
                    .background(.clear) // Чистый фон
                    .cornerRadius(12)
            }
            .chartXAxis {
                AxisMarks(values: chartData.map { $0.date }) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0))
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            let weekdayIndex = calendar.component(.weekday, from: date) - 1
                            let letter = String(calendar.shortWeekdaySymbols[weekdayIndex].prefix(1))
                            Text(letter)
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
            .onTapGesture { location in
                // Простой тап для выбора бара
                handleSimpleTap(location: location)
            }
            .gesture(
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
            )
            .padding(.horizontal, 16)
            .id("week-\(currentWeekIndex)")
        }
    }
    
    // MARK: - Navigation Methods
    
    private func handleSimpleTap(location: CGPoint) {
        // Простая логика: определяем какой день недели по X координате
        let chartWidth: CGFloat = UIScreen.main.bounds.width - 32 // Примерная ширина графика
        let dayWidth = chartWidth / 7
        let tappedDayIndex = Int(location.x / dayWidth)
        
        guard tappedDayIndex >= 0 && tappedDayIndex < chartData.count else { return }
        
        let tappedDate = chartData[tappedDayIndex].date
        
        if selectedDate != nil && calendar.isDate(selectedDate!, inSameDayAs: tappedDate) {
            // Повторный тап - убираем выделение
            selectedDate = nil
        } else {
            // Новый выбор
            selectedDate = tappedDate
            HapticManager.shared.playSelection() // Один раз при выборе
        }
    }
    
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
        
        if !habit.isActiveOnDate(date) {
            return Color.gray.opacity(0.2)
        }
        
        if date > Date() {
            return Color.gray.opacity(0.2)
        }
        
        if value == 0 {
            return Color.gray.opacity(0.3)
        }
        
        // iOS 18+ более богатые цвета
        return AppColorManager.shared.selectedColor.color.mix(with: .white, by: 0.1)
    }
    
    // MARK: - Computed Properties
    
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
    
    // MARK: - Helper Methods
    
    private func setupWeeks() {
        isLoading = true
        
        let today = Date()
        let todayWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        let habitStartWeekStart = calendar.dateInterval(of: .weekOfYear, for: habit.startDate)?.start ?? habit.startDate
        
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
