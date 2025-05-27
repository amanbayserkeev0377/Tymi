import SwiftUI
import SwiftData

struct ArchivedHabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    @Environment(\.editMode) private var editMode
    @ObservedObject private var colorManager = AppColorManager.shared
    
    // Query only archived habits
    @Query(
        filter: #Predicate<Habit> { habit in
            habit.isArchived
        },
        sort: [SortDescriptor(\Habit.createdAt, order: .reverse)]
    )
    private var archivedHabits: [Habit]
    
    @State private var selectedForDeletion: Set<Habit.ID> = []
    @State private var isDeleteSelectedAlertPresented = false
    @State private var selectedHabitForStats: Habit? = nil
    
    var body: some View {
        Group {
            if editMode?.wrappedValue == .active {
                List(selection: $selectedForDeletion) {
                    listContent
                }
            } else {
                List {
                    listContent
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !archivedHabits.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
            
            if !selectedForDeletion.isEmpty {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        // Unarchive button
                        Button {
                            unarchiveSelectedHabits()
                        } label: {
                            HStack {
                                Text("unarchive".localized)
                                Image(systemName: "tray.and.arrow.up")
                            }
                        }
                        .tint(.cyan)
                        
                        Spacer()
                        
                        // Delete button
                        Button {
                            isDeleteSelectedAlertPresented = true
                        } label: {
                            HStack {
                                Text("delete".localized)
                                Image(systemName: "trash")
                            }
                        }
                        .tint(.red)
                    }
                }
            }
        }
        .onChange(of: editMode?.wrappedValue) { _, newValue in
            if newValue != .active {
                selectedForDeletion.removeAll()
            }
        }
        .alert("delete_permanently_confirmation".localized, isPresented: $isDeleteSelectedAlertPresented) {
            Button("cancel".localized, role: .cancel) {}
            Button("delete_permanently".localized, role: .destructive) {
                deleteSelectedHabits()
            }
        } message: {
            Text("delete_permanently_description".localized)
        }
        .sheet(item: $selectedHabitForStats) { habit in
            NavigationStack {
                HabitStatisticsView(habit: habit)
            }
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Navigation Title
    private var navigationTitle: String {
        if editMode?.wrappedValue == .active && !selectedForDeletion.isEmpty {
            return "general_items_selected".localized(with: selectedForDeletion.count)
        } else {
            return "archived_habits".localized
        }
    }
    
    // MARK: - List Content
    @ViewBuilder
    private var listContent: some View {
        if archivedHabits.isEmpty {
            ContentUnavailableView(
                "no_archived_habits".localized,
                systemImage: "archivebox",
                description: Text("archived_habits_empty_description".localized)
            )
            .listRowBackground(Color.clear)
        } else {
            Section {
                ForEach(archivedHabits) { habit in
                    archivedHabitRow(habit)
                }
            }
        }
    }
    
    // MARK: - Archived Habit Row
    @ViewBuilder
    private func archivedHabitRow(_ habit: Habit) -> some View {
        Button {
            // Только если НЕ в edit mode - открываем статистику
            if editMode?.wrappedValue != .active {
                selectedHabitForStats = habit
            }
        } label: {
            HStack {
                // Icon слева
                let iconName = habit.iconName ?? "checkmark"
                
                if iconName.hasPrefix("icon_") {
                    // Кастомная иконка
                    Image(iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                        .foregroundStyle(habit.iconColor.color)
                } else {
                    // SF Symbol
                    Image(systemName: iconName)
                        .font(.title3)
                        .foregroundStyle(habit.iconName == nil ? colorManager.selectedColor.color : habit.iconColor.color)
                        .frame(width: 28, height: 28)
                }
                
                // Название привычки (одна строка)
                Text(habit.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .tint(.primary)
                
                Spacer()
                
                // Unarchive button справа (только если НЕ в edit mode)
                if editMode?.wrappedValue != .active {
                    Button(action: {
                        unarchiveHabit(habit)
                    }) {
                        Image(systemName: "tray.and.arrow.up")
                            .font(.system(size: 16))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(.primary.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Helper Methods
    
    private func unarchiveHabit(_ habit: Habit) {
        habit.isArchived = false
        try? modelContext.save()
        habitsUpdateService.triggerUpdate()
        HapticManager.shared.play(.success)
    }
    
    private func unarchiveSelectedHabits() {
        let habitsToUnarchive = archivedHabits.filter { selectedForDeletion.contains($0.id) }
        
        for habit in habitsToUnarchive {
            habit.isArchived = false
        }
        
        try? modelContext.save()
        habitsUpdateService.triggerUpdate()
        HapticManager.shared.play(.success)
        
        selectedForDeletion.removeAll()
    }
    
    private func deleteSelectedHabits() {
        let habitsToDelete = archivedHabits.filter { selectedForDeletion.contains($0.id) }
        
        for habit in habitsToDelete {
            // Cancel notifications
            NotificationManager.shared.cancelNotifications(for: habit)
            
            // Delete from model context
            modelContext.delete(habit)
        }
        
        try? modelContext.save()
        habitsUpdateService.triggerUpdate()
        HapticManager.shared.play(.error)
        
        selectedForDeletion.removeAll()
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Archived Habits Count Badge

struct ArchivedHabitsCountBadge: View {
    @Query(
        filter: #Predicate<Habit> { habit in
            habit.isArchived
        }
    )
    private var archivedHabits: [Habit]
    
    var body: some View {
        if !archivedHabits.isEmpty {
            Text("\(archivedHabits.count)")
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
        }
    }
}
