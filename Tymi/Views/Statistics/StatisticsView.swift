import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(
        filter: #Predicate<Habit> { habit in
            !habit.isArchived
        },
        sort: [SortDescriptor(\Habit.createdAt)]
    )
    private var allHabits: [Habit]

    // Computed property для правильной сортировки с isPinned
    private var habits: [Habit] {
        allHabits.sorted { first, second in
            // Сначала сортируем по isPinned (pinned наверху)
            if first.isPinned != second.isPinned {
                return first.isPinned && !second.isPinned
            }
            // Потом по дате создания
            return first.createdAt < second.createdAt
        }
    }
    
    @State private var selectedHabitForStats: Habit? = nil
    
    var body: some View {
        NavigationStack {
            List {
                if habits.isEmpty {
                    Text("no_habits".localized)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    Section {
                        ForEach(habits) { habit in
                            Button {
                                selectedHabitForStats = habit
                            } label: {
                                HStack {
                                    if let iconName = habit.iconName {
                                        Image(systemName: iconName)
                                            .foregroundStyle(.primary)
                                            .frame(width: 30)
                                    }
                                    
                                    Text(habit.title)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("statistics".localized)
            .sheet(item: $selectedHabitForStats) { habit in
                NavigationStack {
                    HabitStatisticsView(habit: habit)
                }
                .presentationDragIndicator(.visible)
            }
        }
    }
}
