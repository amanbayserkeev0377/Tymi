import SwiftUI
import SwiftData

enum OverviewTimeRange: String, CaseIterable {
    case week = "W"
    case month = "M"
    case year = "Y"
    
    var localized: String {
        switch self {
        case .week: return "W"
        case .month: return "M"
        case .year: return "Y"
        }
    }
}

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(
        filter: #Predicate<Habit> { habit in
            !habit.isArchived
        },
        sort: [SortDescriptor(\Habit.createdAt)]
    )
    private var allHabits: [Habit]
    
    private var habits: [Habit] {
        allHabits.sorted { first, second in
            if first.isPinned != second.isPinned {
                return first.isPinned && !second.isPinned
            }
            return first.createdAt < second.createdAt
        }
    }
    
    @State private var selectedTimeRange: OverviewTimeRange = .week
    @State private var selectedHabitForStats: Habit? = nil
    
    var body: some View {
        NavigationStack {
            if habits.isEmpty {
                StatisticsEmptyStateView()
            } else {
                List {
                    // Overview Section
                    Section {
                        VStack(spacing: 20) {
                            // Quick stats cards
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                QuickStatCard(
                                    title: "Total Habits",
                                    value: "\(habits.count)",
                                    icon: "list.bullet.clipboard"
                                )
                                
                                QuickStatCard(
                                    title: "Active Today",
                                    value: "\(activeHabitsToday)",
                                    icon: "calendar.badge.clock"
                                )
                                
                                QuickStatCard(
                                    title: "Completed Today",
                                    value: "\(completedToday)",
                                    icon: "checkmark.circle.fill"
                                )
                                
                                QuickStatCard(
                                    title: "Current Streaks",
                                    value: "\(totalActiveStreaks)",
                                    icon: "flame.fill"
                                )
                            }
                            
                            // Overview chart based on selected time range
                            OverviewChart(habits: habits, timeRange: selectedTimeRange)
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    .listRowSeparator(.hidden)
                    
                    // Habits List Section
                    Section("Your Habits") {
                        ForEach(habits) { habit in
                            Button {
                                selectedHabitForStats = habit
                            } label: {
                                HStack {
                                    if let iconName = habit.iconName {
                                        Image(systemName: iconName)
                                            .font(.system(size: 24))
                                            .frame(width: 24, height: 24)
                                            .foregroundStyle(habit.iconColor.color)
                                    }
                                    
                                    Text(habit.title)
                                        .tint(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(Color(uiColor: .systemGray3))
                                        .font(.footnote)
                                        .fontWeight(.bold)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("statistics".localized)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if !habits.isEmpty {
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(OverviewTimeRange.allCases, id: \.self) { range in
                            Text(range.localized).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
            }
        }
        .sheet(item: $selectedHabitForStats) { habit in
            NavigationStack {
                HabitStatisticsView(habit: habit)
            }
            .presentationDragIndicator(.visible)
        }
    }
    
    // Quick computed properties
    private var activeHabitsToday: Int {
        let today = Date()
        return habits.filter { $0.isActiveOnDate(today) }.count
    }
    
    private var completedToday: Int {
        let today = Date()
        return habits.filter { habit in
            habit.isActiveOnDate(today) && habit.progressForDate(today) >= habit.goal
        }.count
    }
    
    private var totalActiveStreaks: Int {
        return habits.compactMap { habit in
            let viewModel = HabitStatsViewModel(habit: habit)
            return viewModel.currentStreak > 0 ? viewModel.currentStreak : nil
        }.reduce(0, +)
    }
}

// ===== Quick Stat Card =====

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(AppColorManager.shared.selectedColor.color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary)
        }
    }
}

// ===== Overview Chart =====

struct OverviewChart: View {
    let habits: [Habit]
    let timeRange: OverviewTimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(chartTitle)
                .font(.headline)
                .fontWeight(.semibold)
            
            // Simple progress visualization
            HStack(spacing: 4) {
                ForEach(0..<daysToShow, id: \.self) { dayOffset in
                    let date = dateForOffset(dayOffset)
                    let completion = completionRate(for: date)
                    
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(completion > 0.8 ? Color.green : 
                                  completion > 0.5 ? AppColorManager.shared.selectedColor.color :
                                  completion > 0 ? AppColorManager.shared.selectedColor.color.opacity(0.5) :
                                  Color.gray.opacity(0.3))
                            .frame(height: max(4, completion * 40))
                            .frame(maxHeight: 40)
                        
                        Text(labelForOffset(dayOffset))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 60)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary)
        }
    }
    
    private var chartTitle: String {
        switch timeRange {
        case .week: return "This Week"
        case .month: return "This Month"
        case .year: return "This Year"
        }
    }
    
    private var daysToShow: Int {
        switch timeRange {
        case .week: return 7
        case .month: return 30
        case .year: return 12
        }
    }
    
    private func dateForOffset(_ offset: Int) -> Date {
        let calendar = Calendar.current
        switch timeRange {
        case .week:
            return calendar.date(byAdding: .day, value: offset - 6, to: Date()) ?? Date()
        case .month:
            return calendar.date(byAdding: .day, value: offset - 29, to: Date()) ?? Date()
        case .year:
            return calendar.date(byAdding: .month, value: offset - 11, to: Date()) ?? Date()
        }
    }
    
    private func labelForOffset(_ offset: Int) -> String {
        let date = dateForOffset(offset)
        let formatter = DateFormatter()
        
        switch timeRange {
        case .week:
            formatter.dateFormat = "E"
            return String(formatter.string(from: date).prefix(1))
        case .month:
            let day = Calendar.current.component(.day, from: date)
            return day % 5 == 0 ? "\(day)" : ""
        case .year:
            formatter.dateFormat = "MMM"
            return String(formatter.string(from: date).prefix(1))
        }
    }
    
    private func completionRate(for date: Date) -> Double {
        let calendar = Calendar.current
        let activeHabits: [Habit]
        
        switch timeRange {
        case .week, .month:
            activeHabits = habits.filter { $0.isActiveOnDate(date) }
        case .year:
            // For year view, get all habits active in this month
            let range = calendar.range(of: .day, in: .month, for: date) ?? 1..<2
            let monthDays = range.compactMap { day in
                calendar.date(byAdding: .day, value: day - 1, to: calendar.startOfMonth(for: date))
            }
            
            let monthActiveHabits = habits.filter { habit in
                monthDays.contains { habit.isActiveOnDate($0) }
            }
            
            let monthCompletedHabits = monthActiveHabits.filter { habit in
                let completedDays = monthDays.filter { day in
                    habit.progressForDate(day) >= habit.goal
                }.count
                return Double(completedDays) / Double(monthDays.count) > 0.5
            }
            
            return monthActiveHabits.isEmpty ? 0 : Double(monthCompletedHabits.count) / Double(monthActiveHabits.count)
        }
        
        guard !activeHabits.isEmpty else { return 0 }
        
        let completedHabits = activeHabits.filter { habit in
            habit.progressForDate(date) >= habit.goal
        }
        
        return Double(completedHabits.count) / Double(activeHabits.count)
    }
}

// Helper extension for Calendar
extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}

// ===== Empty State (keeping existing) =====

struct StatisticsEmptyStateView: View {
    @State private var isAnimating = false
    @ObservedObject private var colorManager = AppColorManager.shared
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: "chart.line.text.clipboard")
                .font(.system(size: 120, weight: .thin))
                .foregroundStyle(colorManager.selectedColor.color.opacity(0.3))
                .scaleEffect(isAnimating ? 1.05 : 0.98)
                .animation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
}
