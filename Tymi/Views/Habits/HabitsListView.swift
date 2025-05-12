import SwiftUI
import SwiftData

struct HabitsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    
    @Query(sort: \Habit.createdAt) private var allHabits: [Habit]
    @State private var selectedHabit: Habit? = nil
    @State private var isShowingNewHabitSheet = false
    
    var body: some View {
        List {
            // Активные привычки
            Section {
                ForEach(activeHabits) { habit in
                    Button {
                        selectedHabit = habit
                    } label: {
                        HabitRow(habit: habit)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("active_habits".localized)
            }
            
            // Замороженные привычки (если есть)
            if !freezedHabits.isEmpty {
                Section {
                    ForEach(freezedHabits) { habit in
                        Button {
                            selectedHabit = habit
                        } label: {
                            HabitRow(habit: habit)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("freezed_habits".localized)
                }
            }
        }
        .navigationTitle("habits".localized)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    isShowingNewHabitSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingNewHabitSheet) {
            NavigationStack {
                NewHabitView()
            }
        }
        .sheet(item: $selectedHabit) { habit in
            NavigationStack {
                HabitDetailView(
                    habit: habit,
                    date: Date(),
                    onDelete: {
                        selectedHabit = nil
                    }
                )
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    private var activeHabits: [Habit] {
        allHabits.filter { !$0.isFreezed }
    }
    
    private var freezedHabits: [Habit] {
        allHabits.filter { $0.isFreezed }
    }
}

// Простая строка списка привычек
struct HabitRow: View {
    let habit: Habit
    
    var body: some View {
        HStack {
            // Иконка привычки
            if let iconName = habit.iconName {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 30)
            }
            
            // Название и цель
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.headline)
                
                Text(habit.formattedGoal)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Индикатор заморозки (если привычка заморожена)
            if habit.isFreezed {
                Image(systemName: "snowflake")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }
        }
    }
}
