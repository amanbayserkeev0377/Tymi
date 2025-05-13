import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: [SortDescriptor(\Habit.createdAt)])
    private var habits: [Habit]
    
    @State private var selectedHabitForStats: Habit? = nil
    
    var body: some View {
        NavigationStack {
            List {
                if habits.isEmpty {
                    Text("У вас пока нет привычек")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    Section(header: Text("Ваши привычки")) {
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
                    
                    // Здесь можно добавить общую статистику или другие разделы
                }
            }
            .navigationTitle("Статистика")
            .sheet(item: $selectedHabitForStats) { habit in
                NavigationStack {
                    HabitStatisticsView(habit: habit)
                }
                // Без presentationDetents для полноэкранного режима
                .presentationDragIndicator(.visible)
            }
        }
    }
}
