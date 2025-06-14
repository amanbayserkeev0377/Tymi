import SwiftUI
import Charts

struct HabitBarChart: View {
    let habit: Habit
    let timeRange: ChartTimeRange
    
    @State private var chartData: [ChartDataPoint] = []
    @State private var selectedDataPoint: ChartDataPoint?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with average
            VStack(alignment: .leading, spacing: 4) {
                Text("DAILY AVERAGE")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                Text(averageValueFormatted)
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColorManager.shared.selectedColor.color)
                
                Text(timeRangeSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Chart
            Chart(chartData) { dataPoint in
                BarMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Progress", dataPoint.value)
                )
                .foregroundStyle(barColor(for: dataPoint))
                .cornerRadius(2)
                .opacity(selectedDataPoint == nil ? 1.0 : 
                        (selectedDataPoint?.id == dataPoint.id ? 1.0 : 0.5))
            }
            .frame(height: chartHeight)
            .chartXAxis {
                AxisMarks(values: xAxisValues) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0))
                    AxisValueLabel(format: xAxisFormat)
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: yAxisValues) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                        .foregroundStyle(.gray.opacity(0.3))
                    AxisValueLabel()
                        .foregroundStyle(.secondary)
                }
            }
            .chartBackground { chartProxy in
                Color.clear
            }
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            handleChartTap(location: location, chartProxy: geometry)
                        }
                }
            }
            .overlay(alignment: .topLeading) {
                // Tooltip
                if let selectedDataPoint = selectedDataPoint {
                    tooltipView(for: selectedDataPoint)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
        }
        .onAppear {
            loadChartData()
        }
        .onChange(of: timeRange) { _, _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedDataPoint = nil
                loadChartData()
            }
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func tooltipView(for dataPoint: ChartDataPoint) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("TOTAL")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            Text(dataPoint.formattedValue)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text(dateFormatter.string(from: dataPoint.date))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
                .shadow(radius: 8, y: 4)
        )
        .padding(.top, 8)
        .padding(.leading, 8)
    }
    
    // MARK: - Computed Properties
    
    private var chartHeight: CGFloat {
        switch timeRange {
        case .week: return 180
        case .month: return 200
        case .year: return 220
        }
    }
    
    private var averageValueFormatted: String {
        guard !chartData.isEmpty else { return "0" }
        
        let total = chartData.reduce(0) { $0 + $1.value }
        let average = total / chartData.count
        
        switch habit.type {
        case .count:
            return "\(average)"
        case .time:
            return average.formattedAsTime()
        }
    }
    
    private var timeRangeSubtitle: String {
        switch timeRange {
        case .week:
            return "This Week"
        case .month:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            return formatter.string(from: Date()).uppercased()
        case .year:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return formatter.string(from: Date())
        }
    }
    
    private var xAxisValues: [Date] {
        switch timeRange {
        case .week:
            return chartData.map { $0.date }
        case .month:
            return Array(stride(from: 0, to: chartData.count, by: 7)).compactMap { 
                chartData.indices.contains($0) ? chartData[$0].date : nil 
            }
        case .year:
            return Array(stride(from: 0, to: chartData.count, by: 30)).compactMap { 
                chartData.indices.contains($0) ? chartData[$0].date : nil 
            }
        }
    }
    
    private var yAxisValues: [Int] {
        guard !chartData.isEmpty else { return [0] }
        
        let maxValue = chartData.map { $0.value }.max() ?? 0
        let stepCount = 3
        let step = max(1, maxValue / stepCount)
        
        return Array(stride(from: 0, through: maxValue + step, by: step)).prefix(4).map { $0 }
    }
    
    private var xAxisFormat: Date.FormatStyle {
        switch timeRange {
        case .week:
            return .dateTime.weekday(.abbreviated)
        case .month:
            return .dateTime.day()
        case .year:
            return .dateTime.month(.abbreviated)
        }
    }
    
    // MARK: - Helper Methods
    
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
    
    private func handleChartTap(location: CGPoint, chartProxy: GeometryProxy) {
        // Find the closest data point to tap location
        guard !chartData.isEmpty else { return }
        
        let xPosition = location.x
        let chartWidth = chartProxy.size.width
        let dataPointWidth = chartWidth / CGFloat(chartData.count)
        let index = Int(xPosition / dataPointWidth)
        
        if index >= 0 && index < chartData.count {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDataPoint = chartData[index]
            }
            
            // Auto-hide tooltip after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedDataPoint = nil
                }
            }
        }
    }
    
    private func loadChartData() {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -timeRange.days, to: endDate) ?? endDate
        
        var data: [ChartDataPoint] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let progress = habit.progressForDate(currentDate)
            
            // Include all days in range, even with 0 progress for better visualization
            if habit.isActiveOnDate(currentDate) {
                let dataPoint = ChartDataPoint(
                    date: currentDate,
                    value: progress,
                    goal: habit.goal,
                    habit: habit
                )
                data.append(dataPoint)
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        chartData = data
    }
    
    // MARK: - Formatters
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}
