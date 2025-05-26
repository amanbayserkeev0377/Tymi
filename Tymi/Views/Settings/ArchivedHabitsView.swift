import SwiftUI
import SwiftData

struct ArchivedHabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    @ObservedObject private var colorManager = AppColorManager.shared
    
    // Query only archived habits
    @Query(
        filter: #Predicate<Habit> { habit in
            habit.isArchived
        },
        sort: [SortDescriptor(\Habit.createdAt, order: .reverse)]
    )
    private var archivedHabits: [Habit]
    
    @State private var habitToDelete: Habit? = nil
    @State private var isDeleteAlertPresented = false
    
    var body: some View {
        List {
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
                        ArchivedHabitRow(habit: habit) {
                            unarchiveHabit(habit)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            // Unarchive action
                            Button {
                                unarchiveHabit(habit)
                            } label: {
                                Label("unarchive".localized, systemImage: "tray.and.arrow.up")
                            }
                            .tint(.blue)
                            
                            // Delete permanently action
                            Button(role: .destructive) {
                                habitToDelete = habit
                                isDeleteAlertPresented = true
                            } label: {
                                Label("delete_permanently".localized, systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button {
                                unarchiveHabit(habit)
                            } label: {
                                Label("unarchive".localized, systemImage: "tray.and.arrow.up")
                            }
                            
                            Button(role: .destructive) {
                                habitToDelete = habit
                                isDeleteAlertPresented = true
                            } label: {
                                Label("delete_permanently".localized, systemImage: "trash")
                            }
                        }
                    }
                } footer: {
                    if !archivedHabits.isEmpty {
                        Text("archived_habits_footer".localized)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("archived_habits".localized)
        .navigationBarTitleDisplayMode(.large)
        .alert("delete_permanently_confirmation".localized, isPresented: $isDeleteAlertPresented) {
            Button("cancel".localized, role: .cancel) {
                habitToDelete = nil
            }
            Button("delete_permanently".localized, role: .destructive) {
                if let habit = habitToDelete {
                    deleteHabitPermanently(habit)
                }
                habitToDelete = nil
            }
        } message: {
            Text("delete_permanently_description".localized)
        }
    }
    
    // MARK: - Helper Methods
    
    private func unarchiveHabit(_ habit: Habit) {
        habit.isArchived = false
        try? modelContext.save()
        habitsUpdateService.triggerUpdate()
        HapticManager.shared.play(.success)
    }
    
    private func deleteHabitPermanently(_ habit: Habit) {
        // Cancel notifications
        NotificationManager.shared.cancelNotifications(for: habit)
        
        // Delete from model context
        modelContext.delete(habit)
        
        try? modelContext.save()
        habitsUpdateService.triggerUpdate()
        HapticManager.shared.play(.error)
    }
}

// MARK: - Archived Habit Row Component

struct ArchivedHabitRow: View {
    let habit: Habit
    let onUnarchive: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var colorManager = AppColorManager.shared
    
    var body: some View {
        HStack {
            // Icon
            let iconName = habit.iconName ?? "checkmark"

            if iconName.hasPrefix("icon_") {
                // Кастомная иконка
                Image(iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundStyle(habit.iconColor.color)
                    .padding(.trailing, 8)
            } else {
                // SF Symbol
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(habit.iconName == nil ? colorManager.selectedColor.color : habit.iconColor.color)
                    .frame(width: 30, height: 30)
                    .padding(.trailing, 8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text("goal_format".localized(with: habit.formattedGoal))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    // Separator dot
                    Text("•")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    // Archive date (using creation date as placeholder)
                    Text("archived_date_format".localized(with: formattedDate(habit.createdAt)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Unarchive button
            Button(action: onUnarchive) {
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
        .padding(.vertical, 4)
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
