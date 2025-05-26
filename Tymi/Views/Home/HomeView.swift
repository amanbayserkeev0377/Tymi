import SwiftUI
import SwiftData

struct HomeView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    
    // Query for all habit folders
    @Query(sort: [SortDescriptor(\HabitFolder.displayOrder)])
    private var allFolders: [HabitFolder]
    
    @Query(
        filter: #Predicate<Habit> { habit in
            !habit.isArchived
        },
        sort: [SortDescriptor(\Habit.displayOrder), SortDescriptor(\Habit.createdAt)]
    )
    private var allBaseHabits: [Habit]

    private var baseHabits: [Habit] {
        let filteredHabits: [Habit]
        
        if let selectedFolder = selectedFolder {
            // Show habits from selected folder
            filteredHabits = allBaseHabits.filter { habit in
                habit.folders?.contains(where: { $0.uuid == selectedFolder.uuid }) ?? false
            }
        } else {
            // Show all habits
            filteredHabits = allBaseHabits
        }
        
        return filteredHabits.sorted { first, second in
            if first.isPinned != second.isPinned {
                return first.isPinned && !second.isPinned
            }
            if first.displayOrder != second.displayOrder {
                return first.displayOrder < second.displayOrder
            }
            return first.createdAt < second.createdAt
        }
    }
    
    @State private var selectedDate: Date = .now
    @State private var showingNewHabit = false
    @State private var selectedHabit: Habit? = nil
    @State private var selectedHabitForStats: Habit? = nil
    @State private var habitToEdit: Habit? = nil
    @State private var alertState = AlertState()
    @State private var habitForProgress: Habit? = nil
    @State private var selectedFolder: HabitFolder? = nil

    // Computed property for filtering habits based on selected date
    private var activeHabitsForDate: [Habit] {
        baseHabits.filter { habit in
            habit.isActiveOnDate(selectedDate) &&
            selectedDate >= habit.startDate
        }
    }
    
    // Whether there are habits for selected date
    private var hasHabitsForDate: Bool {
        return !activeHabitsForDate.isEmpty
    }
    
    // MARK: - Body
    var body: some View {
        let actionService = HabitActionService(
            modelContext: modelContext,
            habitsUpdateService: habitsUpdateService,
            onHabitSelected: { habit in selectedHabit = habit },
            onHabitEditSelected: { habit in habitToEdit = habit },
            onHabitStatsSelected: { habit in selectedHabitForStats = habit }
        )
        
        NavigationStack {
            contentView(actionService: actionService)
        }
    }
    
    private func contentView(actionService: HabitActionService) -> some View {
        VStack(spacing: 0) {
            // Calendar at the top
            WeeklyCalendarView(selectedDate: $selectedDate)
            
            // Folder picker section - after calendar
            if !allFolders.isEmpty {
                folderPickerSection
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
            
            if baseHabits.isEmpty {
                ScrollView {
                    if selectedFolder != nil {
                        // Empty state for selected folder
                        VStack(spacing: 20) {
                            Spacer()
                            Image(systemName: "folder")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                            Text("no_habits_in_folder".localized)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("create_first_habit_in_folder".localized)
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                    } else {
                        EmptyStateView()
                    }
                }
            } else {
                // Habits list
                if hasHabitsForDate {
                    habitList(actionService: actionService)
                } else {
                    Spacer()
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack {
                    Text(formattedNavigationTitle(for: selectedDate))
                        .font(.headline.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    // Folder indicator if selected
                    if let selectedFolder = selectedFolder {
                        Text("• \(selectedFolder.name)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                if !Calendar.current.isDateInToday(selectedDate) {
                    Button(action: {
                        withAnimation {
                            selectedDate = Date()
                        }
                    }) {
                        HStack(spacing: 2) {
                            Text("today".localized)
                                .font(.footnote)
                                .foregroundStyle(Color.gray.opacity(0.7))
                            Image(systemName: "arrow.uturn.left")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.gray.opacity(0.7))
                        }
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.gray.opacity(0.7), lineWidth: 1)
                    )
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    showingNewHabit = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16))
                        .frame(width: 36, height: 36)
                        .padding(4)
                }
            }
        }
        .sheet(isPresented: $showingNewHabit) {
            NewHabitView(initialFolder: selectedFolder)
        }
        .sheet(item: $selectedHabit) { habit in
            NavigationStack {
                HabitDetailView(
                    habit: habit,
                    date: selectedDate,
                    onDelete: {
                        selectedHabit = nil
                    },
                    onShowStats: {
                        selectedHabit = nil
                        selectedHabitForStats = habit
                    }
                )
            }
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(30)
        }
        .sheet(item: $selectedHabitForStats) { habit in
            NavigationStack {
                HabitStatisticsView(habit: habit)
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $habitToEdit) { habit in
            NewHabitView(habit: habit)
        }
        .onChange(of: selectedDate) { _, _ in
            habitsUpdateService.triggerUpdate()
        }
        .alert("delete_habit_confirmation".localized, isPresented: $alertState.isDeleteAlertPresented) {
            Button("cancel".localized, role: .cancel) {
                habitForProgress = nil
            }
            Button("delete".localized, role: .destructive) {
                if let habit = habitForProgress {
                    actionService.deleteHabit(habit)
                }
                habitForProgress = nil
            }
        }
    }
    
    // MARK: - Folder Picker Section
    // MARK: - Folder Picker Section
    private var folderPickerSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFolder = nil
                    }
                } label: {
                    Text("all".localized)
                        .font(.subheadline)
                        .fontWeight(selectedFolder == nil ? .semibold : .regular)
                        .foregroundStyle(selectedFolder == nil ? .primary : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(selectedFolder == nil ? Color.primary.opacity(0.1) : Color.clear)
                        )
                        .overlay(
                            Capsule()
                                .stroke(selectedFolder == nil ? Color.primary.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                
                // Folder buttons - только название, без иконок и цветов
                ForEach(allFolders) { folder in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFolder = selectedFolder?.uuid == folder.uuid ? nil : folder
                        }
                    } label: {
                        Text(folder.name)
                            .font(.subheadline)
                            .fontWeight(selectedFolder?.uuid == folder.uuid ? .semibold : .regular)
                            .foregroundStyle(selectedFolder?.uuid == folder.uuid ? .primary : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(selectedFolder?.uuid == folder.uuid ? Color.primary.opacity(0.1) : Color.clear)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(selectedFolder?.uuid == folder.uuid ? Color.primary.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Habit Views (Native List)
    private func habitList(actionService: HabitActionService) -> some View {
        List {
            ForEach(activeHabitsForDate) { habit in
                HabitRowNative(habit: habit, date: selectedDate) {
                    selectedHabit = habit
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    // Complete action (green)
                    Button {
                        if !habit.isCompletedForDate(selectedDate) {
                            actionService.completeHabit(habit, for: selectedDate)
                        }
                    } label: {
                        Label("complete".localized, systemImage: "checkmark")
                    }
                    .tint(.green)
                    .disabled(habit.isCompletedForDate(selectedDate))
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    // Pin/Unpin (blue)
                    Button {
                        pinHabit(habit)
                    } label: {
                        Label(
                            habit.isPinned ? "unpin".localized : "pin".localized,
                            systemImage: habit.isPinned ? "pin.slash" : "pin"
                        )
                    }
                    .tint(.blue)
                    
                    // Archive (orange)
                    Button {
                        archiveHabit(habit)
                    } label: {
                        Label("archive".localized, systemImage: "archivebox")
                    }
                    .tint(.orange)
                    
                    // Delete (red)
                    Button(role: .destructive) {
                        habitForProgress = habit
                        alertState.isDeleteAlertPresented = true
                    } label: {
                        Label("delete".localized, systemImage: "trash")
                    }
                }
                .contextMenu {
                    // Complete
                    Button {
                        if !habit.isCompletedForDate(selectedDate) {
                            actionService.completeHabit(habit, for: selectedDate)
                        }
                    } label: {
                        Label("complete".localized, systemImage: "checkmarks")
                    }
                    .disabled(habit.isCompletedForDate(selectedDate))
                    
                    Divider()
                    
                    // Move to Folder - Submenu
                    if !allFolders.isEmpty {
                        Menu {
                            // Remove from all folders
                            Button {
                                moveHabitToFolders(habit, folders: [])
                            } label: {
                                Label("no_folder".localized, systemImage: "minus.circle")
                            }
                            
                            Divider()
                            
                            // Individual folders
                            ForEach(allFolders) { folder in
                                Button {
                                    // Toggle folder membership
                                    var currentFolders = Set(habit.folders ?? [])
                                    if currentFolders.contains(folder) {
                                        currentFolders.remove(folder)
                                    } else {
                                        currentFolders.insert(folder)
                                    }
                                    moveHabitToFolders(habit, folders: Array(currentFolders))
                                } label: {
                                    HStack {
                                        Text(folder.name) // убрали иконку
                                        Spacer()
                                        if habit.belongsToFolder(folder) {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label("move_to_folder".localized, systemImage: "folder")
                        }
                    }
                    
                    // Statistics
                    Button {
                        selectedHabitForStats = habit
                    } label: {
                        Label("statistics".localized, systemImage: "chart.line.text.clipboard")
                    }
                    
                    // Edit
                    Button {
                        habitToEdit = habit
                    } label: {
                        Label("edit".localized, systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    // Pin/Unpin
                    Button {
                        pinHabit(habit)
                    } label: {
                        Label(
                            habit.isPinned ? "unpin".localized : "pin".localized,
                            systemImage: habit.isPinned ? "pin.slash" : "pin"
                        )
                    }
                    
                    // Archive
                    Button {
                        archiveHabit(habit)
                    } label: {
                        Label("archive".localized, systemImage: "archivebox")
                    }
                    
                    Divider()
                    
                    // Delete
                    Button(role: .destructive) {
                        habitForProgress = habit
                        alertState.isDeleteAlertPresented = true
                    } label: {
                        Label("delete".localized, systemImage: "trash")
                    }
                }
            }
            .onMove(perform: moveHabits) // Add reorder functionality
        }
        .listStyle(.plain)
    }
    
    // MARK: - Helper Methods
    private func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }
    
    private func isYesterday(_ date: Date) -> Bool {
        return Calendar.current.isDateInYesterday(date)
    }
    
    private func formattedNavigationTitle(for date: Date) -> String {
        if isToday(date) {
            return "today".localized.uppercased()
        } else if isYesterday(date) {
            return "yesterday".localized.uppercased()
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, d MMM"
            return formatter.string(from: date).uppercased()
        }
    }
    
    // MARK: - Move to Folders Method
    private func moveHabitToFolders(_ habit: Habit, folders: [HabitFolder]) {
        habit.removeFromAllFolders()
        for folder in folders {
            habit.addToFolder(folder)
        }
        try? modelContext.save()
        habitsUpdateService.triggerUpdate()
        HapticManager.shared.playSelection()
    }
    
    // MARK: - Pin Method
    private func pinHabit(_ habit: Habit) {
        habit.togglePin()
        try? modelContext.save()
        habitsUpdateService.triggerUpdate()
        HapticManager.shared.playSelection()
    }
    
    // MARK: - Archive Method
    private func archiveHabit(_ habit: Habit) {
        habit.isArchived = true
        try? modelContext.save()
        habitsUpdateService.triggerUpdate()
        HapticManager.shared.play(.success)
    }
    
    // MARK: - Reorder Method
    private func moveHabits(from source: IndexSet, to destination: Int) {
        var habits = activeHabitsForDate
        habits.move(fromOffsets: source, toOffset: destination)
        
        // Update display order for all moved habits
        for (index, habit) in habits.enumerated() {
            habit.displayOrder = index
        }
        
        try? modelContext.save()
        habitsUpdateService.triggerUpdate()
        HapticManager.shared.playSelection()
    }
}
