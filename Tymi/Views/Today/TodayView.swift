import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var habitStore: HabitStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedDate: Date = Date()
    @State private var showingNewHabit = false
    @State private var showingCalendar = false
    @State private var showingSettings = false
    @State private var showingFABMenu = false
    
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
            .blur(radius: showingFABMenu ? 20 : 0)
            
            // FAB Menu background
            if showingFABMenu {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            showingFABMenu = false
                        }
                    }
                    .transition(.opacity)
                
                // Menu items
                VStack(spacing: 24) {
                    Spacer()
                    
                    // New Habit Button
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showingFABMenu = false
                            showingNewHabit = true
                        }
                    } label: {
                        HStack {
                            Text("New Habit")
                                .font(.body)
                            
                            Image(systemName: "plus")
                                .font(.body)
                                .frame(width: 32, height: 32)
                                .background(Color(uiColor: colorScheme == .dark ? .systemGray5 : .systemGray6))
                                .clipShape(Circle())
                        }
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                    
                    // Calendar Button
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showingFABMenu = false
                            showingCalendar = true
                        }
                    } label: {
                        HStack {
                            Text("Calendar")
                                .font(.body)
                            
                            Image(systemName: "calendar")
                                .font(.body)
                                .frame(width: 32, height: 32)
                                .background(Color(uiColor: colorScheme == .dark ? .systemGray5 : .systemGray6))
                                .clipShape(Circle())
                        }
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                    
                    // Settings Button
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showingFABMenu = false
                            showingSettings = true
                        }
                    } label: {
                        HStack {
                            Text("Settings")
                                .font(.body)
                            
                            Image(systemName: "gearshape")
                                .font(.body)
                                .frame(width: 32, height: 32)
                                .background(Color(uiColor: colorScheme == .dark ? .systemGray5 : .systemGray6))
                                .clipShape(Circle())
                        }
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                    
                    Spacer()
                }
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .transition(.opacity)
            }
            
            // FAB Button (only show when menu is not visible)
            if !showingFABMenu {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                showingFABMenu = true
                            }
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
                .transition(.opacity)
            }
            
            // New habit modal
            if showingNewHabit {
                Color.black
                    .opacity(0.05)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            showingNewHabit = false
                        }
                    }
                    .transition(.opacity)
                
                NewHabitView(habitStore: habitStore, isPresented: $showingNewHabit)
                    .transition(.move(edge: .bottom))
                    .zIndex(2)
            }
            
            // Settings placeholder
            if showingSettings {
                Color.black
                    .opacity(0.05)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            showingSettings = false
                        }
                    }
                    .transition(.opacity)
                
                Text("Settings")
                    .font(.title)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
                    .transition(.move(edge: .bottom))
                    .zIndex(2)
            }
        }
        .animation(.spring(response: 0.3), value: showingFABMenu)
        .animation(.spring(response: 0.3), value: showingNewHabit)
        .animation(.spring(response: 0.3), value: showingSettings)
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
