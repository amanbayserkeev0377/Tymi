import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var habitStore: HabitStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedDate: Date = Date()
    @State private var showingNewHabit = false
    @State private var showingCalendar = false
    @State private var showingSettings = false
    @State private var showingFABMenu = false
    @State private var isRotating = false
    @State private var isBreathing = false
    @State private var selectedHabit: Habit?
    @State private var editingHabit: Habit?
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
                                    withAnimation(.easeInOut(duration: 0.3))
                                    {
                                        selectedHabit = habit
                                    }
                                }
                        }
                    }
                    .padding(.top, 24)
                }
            }
            .blur(radius: showingFABMenu || showingNewHabit || showingCalendar || showingSettings || selectedHabit != nil ? 20 : 0)
            
            // FAB Button (only show when no modals are visible)
            if !showingFABMenu && !showingNewHabit && !showingCalendar && !showingSettings && selectedHabit == nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingFABMenu = true
                            }
                        } label: {
                            Image("Tymi_blank")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 56, height: 56)
                                .rotationEffect(.degrees(isRotating ? 360 : 0))
                                .scaleEffect(isBreathing ? 1.06 : 1)
                                .opacity(isBreathing ? 0.05 : 1)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isBreathing)
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(
                                            colorScheme == .dark
                                            ? Color.white.opacity(0.05)
                                            : Color.black.opacity(0.05)
                                        )
                                        .frame(width: 60, height: 60)
                                )
                                .contentShape(Circle())
                                .shadow(
                                    color: Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.8),
                                    radius: 20,
                                    x: 0,
                                    y: 6
                                )
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 32)
                    }
                }
                .transition(.opacity)
            }
            
            // FAB Menu background
            if showingFABMenu {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingFABMenu = false
                        }
                    }
                    .transition(.opacity)
                
                // Menu items
                VStack(spacing: 24) {
                    Spacer()
                    Spacer(minLength: 60)
                    
                    // New Habit Button
                    fabMenuButton(
                        title: "New habit",
                        icon: "plus",
                        action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingFABMenu = false
                                editingHabit = nil
                                showingNewHabit = true
                            }
                        }
                    )
                    
                    // Calendar Button
                    fabMenuButton(
                        title: "Calendar",
                        icon: "calendar",
                        action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingFABMenu = false
                                showingCalendar = true
                            }
                        }
                    )
                    
                    // Settings Button
                    fabMenuButton(
                        title: "Settings",
                        icon: "gearshape",
                        action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingFABMenu = false
                                showingSettings = true
                            }
                        }
                    )
                    
                    Spacer()
                }
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .transition(.opacity)
            }
            
            // New habit modal
            if showingNewHabit {
                Color.black
                    .opacity(0.05)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingNewHabit = false
                            editingHabit = nil
                        }
                    }
                    .transition(.opacity)
                
                if let habit = editingHabit {
                    NewHabitView(
                        habitStore: habitStore,
                        habit: habit,
                        isPresented: $showingNewHabit
                    ) { updatedHabit in
                        habitStore.updateHabit(updatedHabit)
                        editingHabit = nil
                    }
                    .transition(.move(edge: .bottom))
                    .zIndex(2)
                } else {
                    NewHabitView(
                        habitStore: habitStore,
                        isPresented: $showingNewHabit
                    ) { habit in
                        habitStore.addHabit(habit)
                    }
                    .transition(.move(edge: .bottom))
                    .zIndex(2)
                }
            }
            
            // Calendar modal
            if showingCalendar {
                Color.black
                    .opacity(0.05)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingCalendar = false
                        }
                    }
                    .transition(.opacity)
                
                CalendarView(selectedDate: $selectedDate, isPresented: $showingCalendar, habitStore: habitStore)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .zIndex(2)
            }
            
            // Settings modal
            if showingSettings {
                Color.black
                    .opacity(0.05)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
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
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedHabit = nil
                        }
                    }
                
                HabitDetailView(
                    habit: habit,
                    habitStore: habitStore,
                    isPresented: Binding(
                        get: { selectedHabit != nil },
                        set: { if !$0 { selectedHabit = nil } }
                    ),
                    onEdit: { habit in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            editingHabit = habit
                            selectedHabit = nil
                            showingNewHabit = true
                        }
                    },
                    onDelete: { habit in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            habitStore.deleteHabit(habit)
                            selectedHabit = nil
                        }
                    }
                )
                .transition(.move(edge: .bottom))
                .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingFABMenu)
        .animation(.easeInOut(duration: 0.3), value: showingNewHabit)
        .animation(.easeInOut(duration: 0.3), value: showingCalendar)
        .animation(.easeInOut(duration: 0.3), value: showingSettings)
        .animation(.easeInOut(duration: 0.3), value: selectedHabit)
        .navigationBarHidden(true)
        
        .onAppear {
            startFABRotationLoop()
        }
    }
    
    //MARK: - fabMenuButton
    @ViewBuilder
    private func fabMenuButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 19, weight: .regular))
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.9))
                
                Circle()
                    .fill(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.8))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(colorScheme == .dark ? .black.opacity(0.9) : .white.opacity(0.9))
                    )
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .contentShape(Rectangle())
        }
    }
    
    private func startFABRotationLoop() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 1.5)) {
                isRotating.toggle()
            }
        }
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
