import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var habitStore: HabitStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedDate: Date = Date()
    @State private var showingNewHabit = false
    @State private var showingCalendar = false
    @State private var showingSettings = false
    @State private var showingFABMenu = false
    @State private var selectedHabit: Habit?
    @Namespace private var namespace
    
    private var habitsForSelectedDate: [Habit] {
        habitStore.habits.filter { habit in
            let weekday = Calendar.current.component(.weekday, from: selectedDate)
            return habit.activeDays.contains(weekday)
        }
    }
    
    var body: some View {
        ZStack {
            TodayBackground()
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateTitle)
                        .font(.largeTitle.weight(.bold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Tips carousel
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: -15) {
                        ForEach(TipCard.tips) { tip in
                            TipCardView(card: tip, namespace: namespace)
                                .frame(width: UIScreen.main.bounds.width - 140)
                                .frame(height: 300)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                
                // Habits list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(habitsForSelectedDate) { habit in
                            HabitRowView(habit: habit)
                                .padding(.horizontal, 24)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedHabit = habit
                                    }
                                }
                        }
                    }
                    .padding(.top, 24)
                }
            }
            .blur(radius: showingFABMenu || showingNewHabit || showingCalendar || showingSettings || selectedHabit != nil ? 20 : 0)
            
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
            
            // Calendar modal
            if showingCalendar {
                Color.black
                    .opacity(0.05)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            showingCalendar = false
                        }
                    }
                    .transition(.opacity)
                
                CalendarView(selectedDate: $selectedDate, isPresented: $showingCalendar)
                    .transition(.move(edge: .bottom))
                    .zIndex(2)
            }
            
            // Settings modal
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
                
                SettingsView(isPresented: $showingSettings)
                    .transition(.move(edge: .bottom))
                    .zIndex(2)
            }
            
            // Habit Detail Modal
            if let habit = selectedHabit {
                Color.black.opacity(0.05)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            selectedHabit = nil
                        }
                    }
                
                HabitDetailView(habit: habit, isPresented: Binding(
                    get: { selectedHabit != nil },
                    set: { if !$0 { selectedHabit = nil } }
                ))
                .transition(.move(edge: .bottom))
                .zIndex(2)
            }
        }
        .animation(.spring(response: 0.3), value: showingFABMenu)
        .animation(.spring(response: 0.3), value: showingNewHabit)
        .animation(.spring(response: 0.3), value: showingCalendar)
        .animation(.spring(response: 0.3), value: showingSettings)
        .animation(.spring(response: 0.3), value: selectedHabit)
        .navigationBarHidden(true)
    }
    
    private var dateTitle: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: selectedDate)
        
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "E, d MMM"
            return formatter.string(from: selectedDate)
        }
    }
}
