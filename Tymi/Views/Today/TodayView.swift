import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var habitStore: HabitStoreManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingNewHabit = false
    @State private var showingSettings = false
    @State private var showingCalendar = false
    @State private var editingHabit: Habit?
    @State private var selectedDate: Date = Date()
    @State private var selectedHabit: Habit?
    
    // Haptic feedback
    private let feedback = UIImpactFeedbackGenerator(style: .light)
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    private var dateTitle: String {
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: selectedDate)
        
        if calendar.isDate(selected, equalTo: today, toGranularity: .day) {
            return "Today"
        } else if calendar.isDate(selected, equalTo: calendar.date(byAdding: .day, value: -1, to: today)!, toGranularity: .day) {
            return "Yesterday"
        } else {
            return dateFormatter.string(from: selected)
        }
    }
    
    private var habitsForSelectedDate: [Habit] {
        habitStore.habits.filter { habit in
            let weekday = calendar.component(.weekday, from: selectedDate)
            return habit.activeDays.contains(weekday)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if habitsForSelectedDate.isEmpty {
                    EmptyStateView()
                        .padding(.top, 40)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(habitsForSelectedDate) { habit in
                            habitRow(for: habit)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }
            .navigationTitle(dateTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showingCalendar = true
                        } label: {
                            Image(systemName: "calendar")
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                        }
                        
                        Button {
                            showingNewHabit = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewHabit) {
                NavigationStack {
                    NewHabitView(
                        habitStore: habitStore,
                        habit: editingHabit,
                        isPresented: $showingNewHabit,
                        onSave: { habit in
                            if editingHabit != nil {
                                habitStore.updateHabit(habit)
                            } else {
                                habitStore.addHabit(habit)
                            }
                            editingHabit = nil
                        }
                    )
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView(isPresented: $showingSettings)
                }
            }
            .sheet(isPresented: $showingCalendar) {
                CalendarPickerView(selectedDate: $selectedDate)
            }
            .withBackground()
        }
    }
    
    private func habitRow(for habit: Habit) -> some View {
        NavigationLink {
            HabitDetailView(
                habit: habit,
                onEdit: { habit in
                    editingHabit = habit
                    showingNewHabit = true
                },
                onDelete: { habit in
                    habitStore.deleteHabit(habit)
                },
                onUpdate: { habit, value in
                    // TODO: Implement progress update
                },
                onComplete: { habit in
                    // TODO: Implement completion
                }
            )
        } label: {
            HabitRowView(habit: habit)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - EmptyStateView
struct EmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : .white
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No habits for today")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Add a new habit to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

#Preview {
    TodayView()
        .environmentObject(HabitStoreManager())
}


