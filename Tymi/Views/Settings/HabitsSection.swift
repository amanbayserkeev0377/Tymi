import SwiftUI
import SwiftData

struct HabitsSection: View {
    @Query private var habits: [Habit]
    
    init() {
        // Инициализируем запрос для всех привычек
        let descriptor = FetchDescriptor<Habit>()
        _habits = Query(descriptor)
    }
    
    private var activeHabits: Int {
        habits.filter { !$0.isFreezed }.count
    }
    
    private var freezedHabits: Int {
        habits.filter { $0.isFreezed }.count
    }
    
    var body: some View {
        NavigationLink {
            HabitsSettingsView()
        } label: {
            HStack {
                Image(systemName: "list.bullet")
                    .settingsIcon()
                
                Text("Habits")
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("\(activeHabits) Active • \(freezedHabits) Freezed")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }
            .frame(height: 37)
        }
        .tint(.primary)
    }
}

struct HabitsSettingsView: View {
    @Query private var habits: [Habit]
    @Environment(\.dismiss) private var dismiss
    
    init() {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdAt)])
        _habits = Query(descriptor)
    }
    
    var body: some View {
        List {
            Section("Active Habits (\(activeHabits.count))") {
                ForEach(activeHabits) { habit in
                    HabitSettingsRow(habit: habit)
                }
            }
            
            if !freezedHabits.isEmpty {
                Section("Freezed Habits (\(freezedHabits.count))") {
                    ForEach(freezedHabits) { habit in
                        HabitSettingsRow(habit: habit)
                    }
                }
            }
        }
        .navigationTitle("Habits")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var activeHabits: [Habit] {
        habits.filter { !$0.isFreezed }
    }
    
    private var freezedHabits: [Habit] {
        habits.filter { $0.isFreezed }
    }
}

struct HabitSettingsRow: View {
    let habit: Habit
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(habit.title)
                    .foregroundStyle(.primary)
                Text(habit.formattedGoal)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Menu {
                if habit.isFreezed {
                    Button(action: { habit.isFreezed = false }) {
                        Label("Unfreeze", systemImage: "flame")
                    }
                    .tint(.orange)
                } else {
                    Button(action: { habit.isFreezed = true }) {
                        Label("Freeze", systemImage: "snowflake")
                    }
                    .tint(.blue)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.primary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HabitsSettingsView()
    }
    .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
} 
