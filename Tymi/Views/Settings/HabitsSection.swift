import SwiftUI
import SwiftData

struct HabitsSection: View {
    @Query private var habits: [Habit]
    @State private var showingHabitsSettings = false
    
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
        Button {
            showingHabitsSettings = true
        } label: {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundStyle(.primary)
                    .frame(width: 24, height: 24)
                
                Text("Habits")
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("\(activeHabits) Active • \(freezedHabits) Freezed")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.primary)
        .sheet(isPresented: $showingHabitsSettings) {
            HabitsSettingsView()
                .presentationDetents([.fraction(0.8)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(40)
                .presentationBackground {
                    let cornerRadius: CGFloat = 40
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1.5)
                    }
                }
        }
    }
}

struct HabitsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var habits: [Habit]
    @Environment(\.colorScheme) private var colorScheme
    
    init() {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdAt)])
        _habits = Query(descriptor)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Активные привычки
                    if !activeHabits.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Active Habits (\(activeHabits.count))")
                                .font(.headline)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            
                            ForEach(activeHabits) { habit in
                                HabitSettingsRow(habit: habit)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        colorScheme == .dark ?
                                        Color.black.opacity(0.2) :
                                        Color.white.opacity(0.8)
                                    )
                                    .cornerRadius(10)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 16)
                    }
                    
                    // Замороженные привычки
                    if !freezedHabits.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Freezed Habits (\(freezedHabits.count))")
                                .font(.headline)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            
                            ForEach(freezedHabits) { habit in
                                HabitSettingsRow(habit: habit)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        colorScheme == .dark ?
                                        Color.black.opacity(0.2) :
                                        Color.white.opacity(0.8)
                                    )
                                    .cornerRadius(10)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 8)
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.inline)
        }
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
