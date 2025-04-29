import SwiftUI
import SwiftData

struct TodayView: View {
    //MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    @Query(filter: #Predicate<Habit> { !$0.isFreezed },
           sort: \Habit.createdAt)
    private var habits: [Habit]
    
    @State private var selectedDate: Date = .now
    @State private var isShowingNewHabitSheet = false
    @State private var selectedHabit: Habit? = nil
    @State private var isShowingCalendarSheet = false
    @State private var isShowingSettingsSheet = false
    @StateObject private var habitsUpdateService = HabitsUpdateService()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                TodayViewBackground()
                
                ScrollView {
                    VStack(spacing: 0) {
                        if habits.isEmpty {
                            EmptyStateView()
                        } else {
                            DailyProgressRing(date: selectedDate)
                                .environmentObject(habitsUpdateService)
                                .padding(.top, 16)
                            
                            Spacer()
                            
                            // Список привычек
                            VStack(spacing: 12) {
                                ForEach(habits) { habit in
                                    if habit.isActiveOnDate(selectedDate) {
                                        HabitRowView(
                                            habit: habit,
                                            date: selectedDate,
                                            onTap: {
                                                selectedHabit = habit
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.top, 12)
                            .padding(.bottom, 80) // Место для кнопки добавления
                        }
                    }
                }
                
                // AddFloatingButton
                .overlay(alignment: .bottomTrailing) {
                    AddFloatingButton(action: { isShowingNewHabitSheet = true })
                }
                .navigationTitle(formattedNavigationTitle(for: selectedDate))
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            isShowingSettingsSheet = true
                        }) {
                            Image(systemName: "gearshape")
                        }
                        .tint(.primary)
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            isShowingCalendarSheet = true
                        }) {
                            Image(systemName: "calendar")
                        }
                        .tint(.primary)
                    }
                }
                .sheet(isPresented: $isShowingNewHabitSheet) {
                    NewHabitView()
                        .presentationBackground {
                            ZStack {
                                Rectangle().fill(.ultraThinMaterial)
                                if colorScheme != .dark {
                                    Color.white.opacity(0.6)
                                }
                            }
                        }
                }
                .sheet(isPresented: $isShowingCalendarSheet) {
                    CalendarView(selectedDate: $selectedDate)
                        .presentationDetents([.fraction(0.7)])
                        .presentationCornerRadius(40)
                        .presentationBackground {
                            let cornerRadius: CGFloat = 40
                            ZStack {
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(.ultraThinMaterial)
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(
                                        colorScheme == .dark
                                        ? Color.white.opacity(0.1)
                                        : Color.black.opacity(0.15),
                                        lineWidth: 1.5
                                    )
                            }
                        }
                }
                
                .sheet(isPresented: $isShowingSettingsSheet) {
                    SettingsView()
                        .presentationDetents([.fraction(0.8)])
                        .presentationCornerRadius(40)
                        .presentationBackground {
                            let cornerRadius: CGFloat = 40
                            ZStack {
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(.ultraThinMaterial)
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(
                                        colorScheme == .dark
                                        ? Color.white.opacity(0.1)
                                        : Color.black.opacity(0.15),
                                        lineWidth: 1.5
                                    )
                            }
                        }
                }
                
                .sheet(item: $selectedHabit) { habit in
                    HabitDetailView(habit: habit, date: selectedDate)
                        .environmentObject(habitsUpdateService)
                        .presentationDetents([.fraction(0.8)])
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(40)
                        .presentationBackground {
                            let cornerRadius: CGFloat = 40
                            ZStack {
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(.ultraThinMaterial)
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(
                                        colorScheme == .dark
                                        ? Color.white.opacity(0.1)
                                        : Color.black.opacity(0.15),
                                        lineWidth: 1.5
                                    )
                            }
                        }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }
    
    private func isYesterday(_ date: Date) -> Bool {
        return Calendar.current.isDateInYesterday(date)
    }
    
    private func formattedNavigationTitle(for date: Date) -> String {
        if isToday(date) {
            return "Today"
        } else if isYesterday(date) {
            return "Yesterday"
        } else {
            return dateFormatter.string(from: date)
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
