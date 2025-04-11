import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var habitStore: HabitStoreManager
    @State private var showingNewHabit = false
    @State private var showingSettings = false
    @State private var showingCalendar = false
    @State private var editingHabit: Habit?
    @State private var selectedDate: Date = Date()
    
    // Haptic feedback
    private let feedback = UIImpactFeedbackGenerator(style: .light)
    
    private let calendar = Calendar.current
    private let relativeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM yyyy"
        formatter.doesRelativeDateFormatting = true
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
            return relativeDateFormatter.string(from: selected)
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
                            NavigationLink(value: habit) {
                                HabitRowView(habit: habit)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Button {
                        showingCalendar = true
                    } label: {
                        Text(dateTitle)
                            .font(.headline)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewHabit = true
                    } label: {
                        Image(systemName: "plus")
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
            .navigationDestination(for: Habit.self) { habit in
                HabitDetailView(
                    habit: habit,
                    habitStore: habitStore,
                    isPresented: .constant(true),
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
            }
            .sheet(isPresented: $showingCalendar) {
                CalendarPickerView(selectedDate: $selectedDate)
                    .presentationDetents([.medium])
            }
            .withBackground()
        }
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

