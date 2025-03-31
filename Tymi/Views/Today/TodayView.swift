import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var habitStore: HabitStore
    @State private var selectedDate: Date = Date()
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
                    
                    Button(action: { showingCalendar.toggle() }) {
                        Image(systemName: "calendar")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.primary)
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
            .blur(radius: showingCalendar ? 20 : 0)
            
            // Calendar overlay
            if showingCalendar {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            showingCalendar = false
                        }
                    }
                
                VStack {
                    Spacer()
                        .frame(height: 280)
                    
                    CalendarView(selectedDate: $selectedDate, isPresented: $showingCalendar)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .transition(.opacity)
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
            .opacity(showingCalendar ? 0 : 1)
        }
        .sheet(isPresented: $showingNewHabit) {
            NewHabitView(habitStore: habitStore, isPresented: $showingNewHabit)
                .presentationDetents([.fraction(0.7)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(40)
                .presentationBackground(.clear)
        }
        .animation(.spring(response: 0.3), value: showingCalendar)
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
