import SwiftUI
import SwiftData

struct DaysScrollView: View {
    @Binding var selectedDate: Date
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var habitsUpdateService: HabitsUpdateService
    
    @Query private var habits: [Habit]
    
    @State private var visibleDates: [Date] = []
    @State private var progressData: [Date: Double] = [:]
    
    private let calendar = Calendar.current
    private let dayCount = 30 // Показываем 30 дней назад
    
    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        
        let predicate = #Predicate<Habit> { !$0.isFreezed }
        let sortDescriptor = SortDescriptor<Habit>(\.createdAt, order: .forward)
        _habits = Query(filter: predicate, sort: [sortDescriptor])
    }
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(visibleDates, id: \.self) { date in
                        DayProgressItem(
                            date: date,
                            isSelected: calendar.isDate(selectedDate, inSameDayAs: date),
                            progress: progressData[date] ?? 0,
                            onTap: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedDate = date
                                }
                            }
                        )
                        .id(date)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onAppear {
                generateDates()
                loadProgressData()
                
                // Прокручиваем к выбранной дате
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        scrollProxy.scrollTo(selectedDate, anchor: .center)
                    }
                }
            }
            .onChange(of: selectedDate) { _, newDate in
                withAnimation {
                    scrollProxy.scrollTo(newDate, anchor: .center)
                }
            }
            .onChange(of: habitsUpdateService.lastUpdateTimestamp) { _, _ in
                loadProgressData()
            }
        }
        .frame(height: 80)
        .background(
            Rectangle()
                .fill(Color.clear)
                .background(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 1, y: 1)
        )
    }
    
    private func generateDates() {
        let today = Date()
        var dates: [Date] = []
        
        for dayOffset in (0...dayCount).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                dates.append(date)
            }
        }
        
        visibleDates = dates
    }
    
    private func loadProgressData() {
        Task {
            for date in visibleDates {
                let progress = await calculateProgress(for: date)
                
                await MainActor.run {
                    progressData[date] = progress
                }
            }
        }
    }
    
    private func calculateProgress(for date: Date) async -> Double {
        let activeHabits = habits.filter { habit in
            habit.isActiveOnDate(date) && date >= habit.startDate
        }
        
        guard !activeHabits.isEmpty else { return 0 }
        
        let totalProgress = activeHabits.reduce(0.0) { total, habit in
            let percentage = habit.completionPercentageForDate(date)
            return total + percentage
        }
        
        return totalProgress / Double(activeHabits.count)
    }
}
