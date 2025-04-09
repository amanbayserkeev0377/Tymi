import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var habitStore: HabitStoreManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedIndex: Int = 0 // 0 - today, 1-6 - next 6 days
    @State private var showingNewHabit = false
    @State private var showingSettings = false
    @State private var selectedHabit: Habit?
    @State private var editingHabit: Habit?

    private let calendar = Calendar.current
    private let feedback = UIImpactFeedbackGenerator(style: .light)

    // Массив из 7 дней, начиная с сегодняшнего
    private var days: [Date] {
        (0..<7).map { index in
            calendar.date(byAdding: .day, value: index, to: calendar.startOfDay(for: Date()))!
        }
    }

    // Выбранная дата
    private var selectedDate: Date {
        days[selectedIndex]
    }

    // Название месяца для заголовка
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: selectedDate)
    }

    // Полная дата для подзаголовка
    private var dayTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: selectedDate)
    }

    // Привычки для выбранной даты
    private var habitsForSelectedDate: [Habit] {
        habitStore.habits.filter { habit in
            let weekday = calendar.component(.weekday, from: selectedDate)
            return habit.activeDays.contains(weekday)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Header
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(monthTitle)
                            .font(.title.bold())
                            .foregroundStyle(.primary)

                        Spacer()

                        Button {
                            showingNewHabit = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                        }

                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                    }

                    Text(dayTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // MARK: - Day selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<days.count, id: \.self) { index in
                            let date = days[index]
                            DaySelectorItem(
                                date: date,
                                isSelected: index == selectedIndex,
                                isToday: calendar.isDateInToday(date)
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedIndex = index
                                    feedback.impactOccurred()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 10)

                // MARK: - Content
                TabView(selection: $selectedIndex) {
                    ForEach(0..<days.count, id: \.self) { index in
                        DayContentView(
                            date: days[index],
                            habits: habitsForSelectedDate,
                            onHabitSelected: { habit in
                                selectedHabit = habit
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: selectedIndex) { oldValue, newValue in
                    feedback.impactOccurred()
                }
            }
            .withBackground()
            .navigationBarHidden(true)
            .sheet(isPresented: $showingNewHabit) {
                ModalSheetContainer(title: editingHabit == nil ? "New Habit" : "Edit Habit") {
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
                ModalSheetContainer(title: "Settings") {
                    SettingsView(isPresented: $showingSettings)
                }
            }
            .sheet(item: $selectedHabit) { habit in
                ModalSheetContainer(title: habit.name) {
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
            }
        }
    }
}

// MARK: - DaySelectorItem
struct DaySelectorItem: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    
    private var weekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private var day: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(weekday)
                .font(.caption)
                .foregroundStyle(isSelected ? .white : .secondary)
            
            Text(day)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isSelected ? .blue : Color.clear)
                )
                .overlay(
                    Circle()
                        .stroke(isToday ? .blue : Color.clear, lineWidth: 1)
                )
        }
        .frame(width: 44)
    }
}

// MARK: - DayContentView
struct DayContentView: View {
    let date: Date
    let habits: [Habit]
    let onHabitSelected: (Habit) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if habits.isEmpty {
                    EmptyStateView()
                        .padding(.top, 40)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(habits) { habit in
                            Button {
                                onHabitSelected(habit)
                            } label: {
                                HabitRowView(habit: habit)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
    }
}

// MARK: - EmptyStateView
struct EmptyStateView: View {
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
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}

#Preview {
    TodayView()
        .environmentObject(HabitStoreManager())
}

