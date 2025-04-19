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
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Text(dateFormatter.string(from: selectedDate))
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding()
                
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
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    AddFloatingButton(action: { isShowingNewHabitSheet = true })
                }
                .padding()
            }
        }
        .navigationTitle(isToday(selectedDate) ? "Today" : dateFormatter.string(from: selectedDate))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    // Open settings
                }) {
                    Image(systemName: "gearshape")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    // Open calendar
                }) {
                    Image(systemName: "calendar")
                }
            }
        }
        .sheet(isPresented: $isShowingNewHabitSheet) {
            NewHabitView()
        }
    }
    
    // MARK: - Subviews
    
    private var habitsList: some View {
        List {
            ForEach(habits) { habit in
                if habit.isActiveOnDate(selectedDate) {
                    HabitRowView(habit: habit, date: selectedDate)
                        .onTapGesture {
                            // Navigate to habit detail
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
}

#Preview {
    TodayView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
