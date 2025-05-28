import SwiftUI
import SwiftData

struct HomeView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    @ObservedObject private var colorManager = AppColorManager.shared
    @State private var isEditMode = false
    
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
    @State private var selectedForAction: Set<PersistentIdentifier> = []
    @State private var showingMoveToFolder = false

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
    
    // MARK: - Computed Properties
    private var navigationTitle: String {
        if isEditMode && !selectedForAction.isEmpty {
            return "general_items_selected".localized(with: selectedForAction.count)
        } else {
            return formattedNavigationTitle(for: selectedDate)
        }
    }
    
    private var selectedHabitsArray: [Habit] {
        activeHabitsForDate.filter { selectedForAction.contains($0.persistentModelID) }
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
            ZStack {
                contentView(actionService: actionService)
                
                // FAB - показывать только если не в edit mode
                if !isEditMode {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                showingNewHabit = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 24))
                                    .frame(width: 56, height: 56)
                                    .background(
                                        Circle()
                                            .fill(colorManager.selectedColor.color.opacity(0.1))
                                    )
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
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
            .presentationDetents([
                UIDevice.current.userInterfaceIdiom == .pad ? .large :
                UIScreen.main.bounds.height <= 667 ? .fraction(0.8) : .fraction(0.7)
            ])
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
        .sheet(isPresented: $showingMoveToFolder) {
            MoveToFolderView(habits: selectedHabitsArray)
        }
        .onChange(of: isEditMode) { _, newValue in
            if !newValue {
                selectedForAction.removeAll()
            }
        }
        .onChange(of: activeHabitsForDate.count) { _, newCount in
            // Если все привычки исчезли во время edit mode, выходим из него
            if isEditMode && newCount == 0 {
                withAnimation {
                    isEditMode = false
                }
            }
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
                } else if !selectedForAction.isEmpty {
                    deleteSelectedHabits()
                }
                habitForProgress = nil
            }
        }
    }
    
    private func contentView(actionService: HabitActionService) -> some View {
        VStack(spacing: 0) {
            // Calendar at the top - скрывать в edit mode
            if !isEditMode {
                WeeklyCalendarView(selectedDate: $selectedDate)
            }
            
            // Folder picker section - скрывать в edit mode
            if !allFolders.isEmpty && !isEditMode {
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
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            // Today button - скрывать в edit mode
            if !isEditMode {
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
            }
            
            // Edit/Done button
            if !baseHabits.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button(isEditMode ? "done".localized : "edit".localized) {
                        withAnimation {
                            isEditMode.toggle()
                        }
                    }
                }
            }
            
            // Bottom toolbar для edit mode
            if !selectedForAction.isEmpty {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button {
                            showingMoveToFolder = true
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "folder")
                                    .font(.system(size: 16))
                                Text("move".localized)
                                    .font(.caption)
                            }
                        }
                        .disabled(allFolders.isEmpty)
                        
                        Spacer()
                        
                        Button {
                            alertState.isDeleteAlertPresented = true
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16))
                                Text("delete".localized)
                                    .font(.caption)
                            }
                        }
                        .tint(.red)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Navigation Title
    private func formattedNavigationTitle(for date: Date) -> String {
        if isToday(date) {
            return "today".localized.capitalized
        } else if isYesterday(date) {
            return "yesterday".localized.capitalized
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, d MMM"
            return formatter.string(from: date).capitalized
        }
    }
    
    // MARK: - Edit Mode Habit Row
    private func editModeHabitRow(_ habit: Habit) -> some View {
        HStack(spacing: 12) {
            // Icon без ProgressRing
            let iconName = habit.iconName ?? "checkmark"
            
            Image(systemName: iconName)
                .font(.system(size: 26))
                .foregroundStyle(habit.iconName == nil ? colorManager.selectedColor.color : habit.iconColor.color)
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill((habit.iconName == nil ? colorManager.selectedColor.color : habit.iconColor.color).opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("goal_format".localized(with: habit.formattedGoal))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .contentShape(Rectangle()) // КРИТИЧЕСКИ ВАЖНО для selection
    }
    
    // MARK: - Delete Selected Habits
    private func deleteSelectedHabits() {
        let habitsToDelete = activeHabitsForDate.filter { selectedForAction.contains($0.persistentModelID) }
        
        for habit in habitsToDelete {
            NotificationManager.shared.cancelNotifications(for: habit)
            modelContext.delete(habit)
        }
        
        try? modelContext.save()
        habitsUpdateService.triggerUpdate()
        HapticManager.shared.play(.error)
        
        selectedForAction.removeAll()
    }
    
    // MARK: - Folder Picker Section
    private var folderPickerSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // "All" button
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedFolder = nil
                    }
                } label: {
                    Text("all".localized)
                        .font(.footnote)
                        .fontWeight(selectedFolder == nil ? .semibold : .medium)
                        .foregroundStyle(selectedFolder == nil ? .primary : .secondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedFolder == nil ?
                                    AppColorManager.shared.selectedColor.color.opacity(0.1) :
                                    Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(
                                            selectedFolder == nil ?
                                            AppColorManager.shared.selectedColor.color.opacity(0.2) :
                                                Color.clear,
                                            lineWidth: 1
                                        )
                                )
                        )
                }
                .buttonStyle(.plain)
                
                // Folder buttons
                ForEach(allFolders) { folder in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedFolder = selectedFolder?.uuid == folder.uuid ? nil : folder
                        }
                    } label: {
                        Text(folder.name)
                            .font(.footnote)
                            .fontWeight(selectedFolder?.uuid == folder.uuid ? .semibold : .medium)
                            .foregroundStyle(selectedFolder?.uuid == folder.uuid ? .primary : .secondary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedFolder?.uuid == folder.uuid ?
                                        AppColorManager.shared.selectedColor.color.opacity(0.1) :
                                        Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(
                                                selectedFolder?.uuid == folder.uuid ?
                                                AppColorManager.shared.selectedColor.color.opacity(0.2) :
                                                    Color.clear,
                                                lineWidth: 1
                                            )
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Habit Views (Native List)
    private func habitList(actionService: HabitActionService) -> some View {
        Group {
            if isEditMode {
                List(selection: $selectedForAction) {
                    ForEach(activeHabitsForDate) { habit in
                        editModeHabitRow(habit)
                            .tag(habit.persistentModelID)
                    }
                    .onMove(perform: moveHabits) // Перетаскивание в edit mode
                }
                .listStyle(.plain)
                .environment(\.editMode, .constant(.active)) // Принудительно активируем edit mode для List
            } else {
                List {
                    ForEach(activeHabitsForDate) { habit in
                        HabitRowView(habit: habit, date: selectedDate) {
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
                            // Delete
                            Button(role: .destructive) {
                                habitForProgress = habit
                                alertState.isDeleteAlertPresented = true
                            } label: {
                                Label("delete".localized, systemImage: "trash")
                            }
                            .tint(.red)
                            
                            // Archive
                            Button {
                                archiveHabit(habit)
                            } label: {
                                Label("archive".localized, systemImage: "archivebox")
                            }
                            .tint(.gray)
                            
                            // Pin/Unpin
                            Button {
                                pinHabit(habit)
                            } label: {
                                Label(
                                    habit.isPinned ? "unpin".localized : "pin".localized,
                                    systemImage: habit.isPinned ? "pin.slash" : "pin"
                                )
                            }
                            .tint(.orange)
                        }
                        .contextMenu {
                            // Complete
                            Button {
                                if !habit.isCompletedForDate(selectedDate) {
                                    actionService.completeHabit(habit, for: selectedDate)
                                }
                            } label: {
                                Label("complete".localized, systemImage: "checkmark")
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
                                                Text(folder.name)
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
                            // Pin/Unpin
                            Button {
                                pinHabit(habit)
                            } label: {
                                Label(
                                    habit.isPinned ? "unpin".localized : "pin".localized,
                                    systemImage: habit.isPinned ? "pin.slash" : "pin"
                                )
                            }
                            
                            // Edit
                            Button {
                                habitToEdit = habit
                            } label: {
                                Label("edit".localized, systemImage: "pencil")
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
                            .tint(.red)
                        }
                    }
                    // Перетаскивание только в обычном режиме
                    // .onMove(perform: moveHabits) - убираем отсюда
                }
                .listStyle(.plain)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }
    
    private func isYesterday(_ date: Date) -> Bool {
        return Calendar.current.isDateInYesterday(date)
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
