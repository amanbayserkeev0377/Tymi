import SwiftUI
import SwiftData

struct ReorderHabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    
    @Query(sort: [SortDescriptor(\Habit.displayOrder), SortDescriptor(\Habit.createdAt)])
    private var habits: [Habit]
    
    @State private var editMode: EditMode = .active
    
    // Свойство, чтобы определить, как было открыто представление
    var isSheetPresentation: Bool = false
    
    var body: some View {
        List {
            if habits.isEmpty {
                Text("no_habits".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                    .padding()
            } else {
                ForEach(habits) { habit in
                    HStack {
                        if let iconName = habit.iconName {
                            Image(systemName: iconName)
                                .foregroundStyle(.primary)
                                .frame(width: 30)
                        }
                        
                        Text(habit.title)
                            .font(.headline)
                            .lineLimit(1)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let habit = habits[index]
                        NotificationManager.shared.cancelNotifications(for: habit)
                        modelContext.delete(habit)
                    }
                    habitsUpdateService.triggerUpdate()
                }
                .onMove { indices, newOffset in
                    // Создаём временную копию списка
                    var updatedHabits = habits
                    updatedHabits.move(fromOffsets: indices, toOffset: newOffset)
                    
                    // Обновляем порядок
                    for (index, habit) in updatedHabits.enumerated() {
                        habit.displayOrder = index
                    }
                    
                    try? modelContext.save()
                    habitsUpdateService.triggerUpdate()
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("reorder_habits".localized)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
    }
}
