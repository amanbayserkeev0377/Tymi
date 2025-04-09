import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var habitStore: HabitStoreManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedDate: Date = Date()
    @State private var showingNewHabit = false
    @State private var showingCalendar = false
    @State private var showingSettings = false
    @State private var selectedHabit: Habit?
    @State private var editingHabit: Habit?
    
    private var habitsForSelectedDate: [Habit] {
        habitStore.habits.filter { habit in
            let weekday = Calendar.current.component(.weekday, from: selectedDate)
            return habit.activeDays.contains(weekday)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Tips Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Tips & Insights")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(TipCard.tips) { tip in
                                    TipItemView(tip: tip)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Habits Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today's Habits")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                        
                        LazyVStack(spacing: 12) {
                            if habitsForSelectedDate.isEmpty {
                                EmptyStateView()
                            } else {
                                ForEach(habitsForSelectedDate) { habit in
                                    Button {
                                        selectedHabit = habit
                                    } label: {
                                        HabitRowView(habit: habit)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingNewHabit = true
                        } label: {
                            Label("New Habit", systemImage: "plus")
                        }
                        
                        Button {
                            showingCalendar = true
                        } label: {
                            Label("Calendar", systemImage: "calendar")
                        }
                        
                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.body.weight(.medium))
                    }
                }
            }
            .sheet(isPresented: $showingNewHabit) {
                NavigationStack {
                    if let habit = editingHabit {
                        NewHabitView(
                            habitStore: habitStore,
                            habit: habit,
                            isPresented: $showingNewHabit
                        ) { updatedHabit in
                            habitStore.updateHabit(updatedHabit)
                            editingHabit = nil
                        }
                    } else {
                        NewHabitView(
                            habitStore: habitStore,
                            isPresented: $showingNewHabit
                        ) { habit in
                            habitStore.addHabit(habit)
                        }
                    }
                }
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingCalendar) {
                NavigationStack {
                    CalendarView(isPresented: $showingCalendar)
                }
                .presentationDragIndicator(.visible)
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView(isPresented: $showingSettings)
                }
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedHabit) { habit in
                NavigationStack {
                    HabitDetailView(
                        habit: habit,
                        habitStore: habitStore,
                        isPresented: Binding(
                            get: { selectedHabit != nil },
                            set: { if !$0 { selectedHabit = nil } }
                        ),
                        onEdit: { habit in
                            editingHabit = habit
                            selectedHabit = nil
                            showingNewHabit = true
                        },
                        onDelete: { habit in
                            habitStore.deleteHabit(habit)
                            selectedHabit = nil
                        }
                    )
                }
                .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - TipItemView
struct TipItemView: View {
    let tip: TipCard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icons
            HStack(spacing: 12) {
                Image(systemName: tip.icon)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(tip.gradient[0]))
                
                Spacer()
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(tip.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            // Metadata
            HStack {
                Image(systemName: "clock")
                    .font(.caption.weight(.medium))
                Text("3 min read")
                    .font(.caption.weight(.medium))
                Spacer()
            }
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 280)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
    }
}
