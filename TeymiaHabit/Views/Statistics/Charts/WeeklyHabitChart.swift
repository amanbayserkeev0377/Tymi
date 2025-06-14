import SwiftUI
import Charts

struct WeeklyHabitChart: View {
    // MARK: - Properties
    let habit: Habit
    
    // MARK: - State
    @State private var weeks: [Date] = [] // Список начал недель
    @State private var currentWeekIndex: Int = 0
    @State private var chartData: [ChartDataPoint] = []
    @State private var selectedDataPoint: ChartDataPoint?
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
            
            // Chart (дни недели показываются нативно внизу)
            chartView
        }
        .onAppear {
            setupWeeks()
            findCurrentWeekIndex()  
            generateChartData()
        }
        .onChange(of: habit.goal) { _, _ in
            // Обновляем chart при изменении goal
            generateChartData()
        }
        .onChange(of: habit.activeDays) { _, _ in
            // Обновляем chart при изменении активных дней
            generateChartData()
        }
    }
    
    // MARK: - Header View
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 12) {
            // Week range в самый верх по центру
            HStack {
                // Previous week button (слева)
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
                
                // Week range (по центру в самом верху)
                Text(weekRangeString)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                // Next week button (справа)
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
            
            // Stats row - AVERAGE слева, TOTAL справа (ниже weekRange)
            HStack {
                // AVERAGE (слева)
                VStack(alignment: .leading, spacing: 2) {
                    if let selectedDataPoint = selectedDataPoint {
                        // Selected day stats
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
                        // Weekly average
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
                
                // TOTAL (справа)
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
            Text("No data for this week")
                .frame(height: 200)
                .foregroundStyle(.secondary)
        } else {
            Chart(chartData) { dataPoint in
                BarMark(
                    x: .value("Day", dataPoint.date, unit: .day),
                    y: .value("Progress", dataPoint.value)
                )
                .foregroundStyle(barColor(for: dataPoint))
                .cornerRadius(2)
                .opacity(selectedDataPoint == nil ? 1.0 : 
                        (selectedDataPoint?.id == dataPoint.id ? 1.0 : 0.5))
            }
            .frame(height: 200)
            .padding(.horizontal, 8) // Добавляем padding чтобы буквы не обрезались
            .chartXAxis {
                // Принудительно показываем ВСЕ дни недели с правильным выравниванием
                AxisMarks(values: chartData.map { $0.date }) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0))
                    AxisValueLabel(centered: true) {
                        if let date = value.as(Date.self) {
                            let weekdayIndex = calendar.component(.weekday, from: date) - 1
                            let letter = String(calendar.shortWeekdaySymbols[weekdayIndex].prefix(1))
                            Text(letter)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
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
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(intValue)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            handleChartTap(location: location, geometry: geometry)
                        }
                }
            }
            .gesture(
                // Swipe gesture for week navigation (non-conflicting)
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        let horizontalDistance = value.translation.width
                        let verticalDistance = abs(value.translation.height)
                        
                        // Only handle primarily horizontal swipes
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
            .id("week-\(currentWeekIndex)")
        }
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
            // Same month
            let startDay = calendar.component(.day, from: currentWeekStart)
            let endDay = calendar.component(.day, from: currentWeekEnd)
            formatter.dateFormat = "MMM yyyy"
            let monthYear = formatter.string(from: currentWeekStart)
            return "\(startDay)–\(endDay) \(monthYear)"
        } else {
            // Different months
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
    
    // Форматирование времени без секунд для графиков
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
        
        // Для времени показываем в часах, а не в секундах
        let displayMaxValue = habit.type == .time ? maxValue / 3600 : maxValue
        let stepCount = 3
        let step = max(1, displayMaxValue / stepCount)
        
        let values = Array(stride(from: 0, through: displayMaxValue + step, by: step)).prefix(4).map { $0 }
        
        // Конвертируем обратно в секунды для времени
        return habit.type == .time ? values.map { $0 * 3600 } : values
    }
    
    private var canNavigateToPreviousWeek: Bool {
        return currentWeekIndex > 0
    }
    
    private var canNavigateToNextWeek: Bool {
        guard !weeks.isEmpty else { return false }
        
        // Don't go beyond current week
        let today = Date()
        let todayWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        return currentWeekIndex < weeks.count - 1 && currentWeekStart < todayWeekStart
    }
    
    // MARK: - Helper Methods
    
    private func setupWeeks() {
        isLoading = true
        
        let today = Date()
        let todayWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        // Calculate habit start week
        let habitStartWeekStart = calendar.dateInterval(of: .weekOfYear, for: habit.startDate)?.start ?? habit.startDate
        
        // Generate weeks from habit start to current week
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
        
        // Find index of current week
        if let index = weeks.firstIndex(where: { calendar.isDate($0, equalTo: todayWeekStart, toGranularity: .day) }) {
            currentWeekIndex = index
        } else {
            // Fallback to last week if current week not found
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
        
        // Генерируем данные для ВСЕХ 7 дней недели принудительно
        for dayOffset in 0...6 {  // 0...6 чтобы получить точно 7 дней
            guard let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            
            let progress = habit.isActiveOnDate(currentDate) && currentDate >= habit.startDate && currentDate <= Date() 
                ? habit.progressForDate(currentDate) 
                : 0
            
            let dataPoint = ChartDataPoint(
                date: currentDate,
                value: progress,
                goal: habit.goal, // Используем актуальный goal
                habit: habit
            )
            data.append(dataPoint)
        }
        
        print("Generated \(data.count) chart data points") // Debug
        chartData = data
    }
    
    private func barColor(for dataPoint: ChartDataPoint) -> Color {
        if dataPoint.isOverAchieved {
            return .green
        } else if dataPoint.isCompleted {
            return AppColorManager.shared.selectedColor.color
        } else if dataPoint.value > 0 {
            return AppColorManager.shared.selectedColor.color.opacity(0.6)
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    private func handleChartTap(location: CGPoint, geometry: GeometryProxy) {
        guard !chartData.isEmpty else { return }
        
        let xPosition = location.x
        let chartWidth = geometry.size.width
        let dataPointWidth = chartWidth / CGFloat(chartData.count)
        let index = Int(xPosition / dataPointWidth)
        
        if index >= 0 && index < chartData.count {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDataPoint = chartData[index]
            }
            
            // Auto-hide selection after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedDataPoint = nil
                }
            }
        }
    }
    
    private func showPreviousWeek() {
        guard canNavigateToPreviousWeek else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentWeekIndex -= 1
            selectedDataPoint = nil
            generateChartData()
        }
    }
    
    private func showNextWeek() {
        guard canNavigateToNextWeek else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentWeekIndex += 1
            selectedDataPoint = nil
            generateChartData()
        }
    }
    
    // MARK: - Formatters
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    private let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}
