import SwiftUI
import SwiftData

struct HabitsSection: View {
    @Query private var habits: [Habit]
    @State private var showingHabitsSettings = false
    @StateObject private var habitsUpdateService = HabitsUpdateService()
    
    init() {
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
                
                Text("Habits".localized)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.primary)
        .sheet(isPresented: $showingHabitsSettings) {
            HabitsSettingsView()
                .environmentObject(habitsUpdateService)
                .presentationDetents([.fraction(0.8)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(40)
                .presentationBackground {
                    let cornerRadius: CGFloat = 40
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1.5)
                    }
                }
        }
    }
}

struct HabitsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var habitsUpdateService: HabitsUpdateService
    @State private var activeHabitsOrder: [Habit] = []
    @State private var editMode: EditMode = .inactive
    @State private var selectedTab: HabitsTab = .active
    
    enum HabitsTab {
        case active
        case freezed
    }
    
    init() {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdAt)])
        _habits = Query(descriptor)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Сегментированный выбор
                Picker("", selection: $selectedTab) {
                    Text("Active (%lld)".localized(with: activeHabits.count))
                        .tag(HabitsTab.active)
                    Text("Freezed (%lld)".localized(with: freezedHabits.count))
                        .tag(HabitsTab.freezed)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Контент в зависимости от выбранной вкладки
                if selectedTab == .active {
                    activeHabitsView
                } else {
                    freezedHabitsView
                }
            }
            .navigationTitle("Habits".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if selectedTab == .active {
                        Button {
                            editMode = editMode.isEditing ? .inactive : .active
                        } label: {
                            Text(editMode.isEditing ? "Done".localized : "Edit".localized)
                        }
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .onChange(of: editMode) { oldValue, newValue in
                if oldValue == .active && newValue == .inactive {
                    updateHabitsOrder()
                }
            }
            .onChange(of: habitsUpdateService.lastUpdateTimestamp) { _, _ in
                updateActiveHabitsOrder()
            }
            .onAppear {
                updateActiveHabitsOrder()
            }
        }
        .tint(.primary)
    }
    
    private var activeHabitsView: some View {
        VStack(spacing: 16) {
            if !activeHabitsOrder.isEmpty {
                List {
                    ForEach(activeHabitsOrder) { habit in
                        HabitSettingsRow(habit: habit)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.visible)
                            .listRowBackground(
                                colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.9)
                            )
                    }
                    .onMove { from, to in
                        activeHabitsOrder.move(fromOffsets: from, toOffset: to)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            } else {
                Text("No active habits".localized)
                    .foregroundStyle(.secondary)
                    .padding(.top, 40)
            }
            
            Spacer(minLength: 40)
        }
        .padding(.top, 8)
    }
    
    private var freezedHabitsView: some View {
        VStack(spacing: 16) {
            if !freezedHabits.isEmpty {
                List {
                    ForEach(freezedHabits) { habit in
                        HabitSettingsRow(habit: habit)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.visible)
                            .listRowBackground(
                                colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.9)
                            )
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            } else {
                Text("No freezed habits".localized)
                    .foregroundStyle(.secondary)
                    .padding(.top, 40)
            }
            
            Spacer(minLength: 40)
        }
        .padding(.top, 8)
    }
    
    private var activeHabits: [Habit] {
        habits.filter { !$0.isFreezed }
    }
    
    private var freezedHabits: [Habit] {
        habits.filter { $0.isFreezed }
    }
    
    private func updateHabitsOrder() {
        for (index, habit) in activeHabitsOrder.enumerated() {
            let newDate = Calendar.current.date(byAdding: .second, value: index, to: Date()) ?? Date()
            habit.createdAt = newDate
        }
        try? modelContext.save()
    }
    
    private func updateActiveHabitsOrder() {
        activeHabitsOrder = activeHabits
    }
}

struct HabitSettingsRow: View {
    let habit: Habit
    @Environment(\.editMode) private var editMode
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var habitsUpdateService: HabitsUpdateService
    @State private var isShowingEditSheet = false
    @State private var isDeleteAlertPresented = false
    
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
            
            if editMode?.wrappedValue == .inactive {
                Menu {
                    Button(action: { isShowingEditSheet = true }) {
                        Label("Edit".localized, systemImage: "pencil")
                    }
                    
                    if habit.isFreezed {
                        Button(action: {
                            habit.isFreezed = false
                            habitsUpdateService.triggerUpdate()
                        }) {
                            Label("Unfreeze".localized, systemImage: "flame")
                        }
                    } else {
                        Button(action: {
                            habit.isFreezed = true
                            habitsUpdateService.triggerUpdate()
                        }) {
                            Label("Freeze".localized, systemImage: "snowflake")
                        }
                    }
                    
                    Button(role: .destructive, action: { isDeleteAlertPresented = true }) {
                        Label("Delete".localized, systemImage: "trash")
                    }
                    .tint(.red)
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            NewHabitView(habit: habit)
        }
        .deleteHabitAlert(isPresented: $isDeleteAlertPresented) {
            modelContext.delete(habit)
        }
    }
}

#Preview {
    NavigationStack {
        HabitsSettingsView()
    }
    .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
