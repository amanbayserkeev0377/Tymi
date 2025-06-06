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
    @State private var habitToDelete: Habit? = nil
    @State private var isDeleteSingleAlertPresented = false
    
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
                                Text("button_delete".localized)
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
        .deleteSingleHabitAlert(
            isPresented: $isDeleteSingleAlertPresented,
            habitName: habitToDelete?.title ?? "",
            onDelete: {
                if let habit = habitToDelete {
                    deleteHabit(habit)
                }
                habitToDelete = nil
            }
        )
        .deleteMultipleHabitsAlert(
            isPresented: $isDeleteSelectedAlertPresented,
            habitsCount: selectedForDeletion.count,
            onDelete: {
                deleteSelectedHabits()
            }
        )
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
            return "items_selected".localized(with: selectedForDeletion.count)
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
                systemImage: "archivebox"
            )
            .listRowBackground(Color.clear)
        } else {
            // ИСПРАВЛЕНО: Добавлен footer с подсказкой
            Section(
                footer: Text("archived_habits_footer".localized)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            ) {
                ForEach(archivedHabits) { habit in
                    archivedHabitRow(habit)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            // Delete action (red)
                            Button(role: .destructive) {
                                habitToDelete = habit
                                isDeleteSingleAlertPresented = true
                            } label: {
                                Label("button_delete".localized, systemImage: "trash")
                            }
                            .tint(.red)
                            
                            // Unarchive action (cyan)
                            Button {
                                unarchiveHabit(habit)
                            } label: {
                                Label("unarchive".localized, systemImage: "tray.and.arrow.up")
                            }
                            .tint(.cyan)
                        }
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
                
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .frame(width: 24, height: 24)
                    .foregroundStyle(habit.iconName == nil ? colorManager.selectedColor.color : habit.iconColor.color)
                
                // Название привычки (одна строка)
                Text(habit.title)
                    .tint(.primary)
                
                Spacer()
                
                // Chevron для показа что можно нажать (как в StatisticsView)
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color(uiColor: .systemGray3))
                    .font(.footnote)
                    .fontWeight(.bold)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func unarchiveHabit(_ habit: Habit) {
        habit.isArchived = false
        try? modelContext.save()
        habitsUpdateService.triggerUpdate()
        HapticManager.shared.play(.success)
    }
    
    private func deleteHabit(_ habit: Habit) {
        // Cancel notifications
        NotificationManager.shared.cancelNotifications(for: habit)
        
        // Delete from model context
        modelContext.delete(habit)
        
        try? modelContext.save()
        habitsUpdateService.triggerUpdate()
        HapticManager.shared.play(.error)
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
