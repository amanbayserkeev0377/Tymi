import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var habitStore: HabitStore
    @State private var selectedDate = Date()
    @State private var showingNewHabit = false
    @State private var showingCalendar = false
    
    private var habitsForSelectedDate: [Habit] {
        habitStore.habits.filter { habit in
            let weekday = Calendar.current.component(.weekday, from: selectedDate)
            return habit.activeDays.contains(weekday)
        }
    }
    
    var body: some View {
        ZStack {
            TodayBackground()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text(dateTitle)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button {
                        showingCalendar = true
                    } label: {
                        Image(systemName: "calendar")
                            .font(.title3)
                    }
                    
                    Button {
                        // TODO: Show settings
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title3)
                    }
                }
                .padding(.horizontal)
                
                // Content
                if habitsForSelectedDate.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(habitsForSelectedDate) { habit in
                                HabitRowView(habit: habit)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            
            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showingNewHabit = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(width: 45, height: 45)
                            .glassCard()
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingNewHabit) {
            NewHabitView(habitStore: habitStore)
        }
        .sheet(isPresented: $showingCalendar) {
            // TODO: Show calendarview
        }
    }
    
    private var dateTitle: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: selectedDate)
        
        if calendar.isDate(selected, inSameDayAs: today) {
            return "Today"
        } else if calendar.isDate(selected, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today)!) {
            return "Yesterday"
        } else if calendar.isDate(selected, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: today)!) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, d MMMM"
            return formatter.string(from: selectedDate)
        }
    }
}
