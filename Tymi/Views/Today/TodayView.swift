import SwiftUI
import SwiftData

struct TodayView: View {
    //MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<Habit> { !$0.isArchived },
           sort: \Habit.createdAt)
    private var habits: [Habit]
    
    @State private var selectedDate: Date = .now
    @State private var isShowingNewHabitSheet = false
    @State private var selectedHabit: Habit? = nil
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if habits.isEmpty {
                    EmptyStateView(
                        icon: "star.circle",
                        title: "No Habits Yet",
                        message: "Tap the + button to add your first habit"
                    )
                } else {
                    habitsList
                }
            }
            .overlay(alignment: .bottomTrailing) {
                AddFloatingButton(action: { isShowingNewHabitSheet = true })
                    .padding()
            }
            .navigationTitle(formattedNavigationTitle(for: selectedDate))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        // Open settings
                    }) {
                        Image(systemName: "gearshape")
                    }
                    .tint(.primary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        // Open calendar
                    }) {
                        Image(systemName: "calendar")
                    }
                    .tint(.primary)
                }
            }
            .sheet(isPresented: $isShowingNewHabitSheet) {
                NewHabitView()
            }
            .sheet(item: $selectedHabit) { habit in
                HabitDetailView(habit: habit, date: selectedDate)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var habitsList: some View {
        List {
            ForEach(habits) { habit in
                if habit.isActiveOnDate(selectedDate) {
                    HabitRowView(habit: habit, date: selectedDate)
                        .onTapGesture {
                            selectedHabit = habit
                        }
                }
            }
        }
        .listStyle(.plain)
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
