import SwiftUI
import SwiftData

struct HomeView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    
    @Query(sort: [SortDescriptor(\Habit.displayOrder), SortDescriptor(\Habit.createdAt)])
    private var baseHabits: [Habit]
    
    @State private var selectedDate: Date = .now
    @State private var isShowingNewHabitSheet = false
    @State private var selectedHabit: Habit? = nil
    @State private var selectedHabitForStats: Habit? = nil
    @State private var isReorderingSheetPresented = false
    
    @State private var actionService: HabitActionService
    
    init() {
        let container = try! ModelContainer(for: Habit.self, HabitCompletion.self)
        _actionService = State(initialValue: HabitActionService(
            modelContext: container.mainContext,
            habitsUpdateService: HabitsUpdateService()
        ))
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMM")
        return formatter
    }()
    
    // Вычисляемое свойство для фильтрации привычек на основе выбранной даты
    private var activeHabitsForDate: [Habit] {
        baseHabits.filter { habit in
            habit.isActiveOnDate(selectedDate) &&
            selectedDate >= habit.startDate
        }
    }
    
    // Имеются ли привычки для выбранной даты
    private var hasHabitsForDate: Bool {
        return !activeHabitsForDate.isEmpty
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            if baseHabits.isEmpty {
                                // Нет привычек вообще
                                EmptyStateView()
                            } else {
                                // Кольцо прогресса отображается всегда
                                DailyProgressRing(date: selectedDate)
                                    .padding(.top, 16)
                                
                                // Список привычек для выбранной даты
                                if hasHabitsForDate {
                                    habitList
                                } else {
                                    // Специальное сообщение, если нет привычек на выбранную дату
                                    if !Calendar.current.isDateInToday(selectedDate) {
                                        Text("try_selecting_today".localized)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.top, 20)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(formattedNavigationTitle(for: selectedDate))
            .navigationBarTitleDisplayMode(.large)
            .safeAreaInset(edge: .top, spacing: 0) {
                WeeklyCalendarView(selectedDate: $selectedDate)
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
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
                                Image(systemName: "arrow.right")
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
                        isShowingNewHabitSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingNewHabitSheet) {
                NavigationStack {
                    NewHabitView()
                }
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
                .presentationDetents([.fraction(0.7)])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedHabitForStats) { habit in
                NavigationStack {
                    HabitStatisticsView(habit: habit)
                }
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isReorderingSheetPresented) {
                NavigationStack {
                    ReorderHabitsView(isSheetPresentation: true)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .onChange(of: selectedDate) { _, _ in
                habitsUpdateService.triggerUpdate()
            }
            .onAppear {
                // Обновляем сервис действий с правильными объектами
                actionService.updateContext(modelContext)
                actionService.updateService(habitsUpdateService)
                actionService.setCallbacks(
                    onHabitSelected: { habit in
                        selectedHabit = habit
                    },
                    onHabitEditSelected: { habit in
                        selectedHabit = habit
                    },
                    onHabitStatsSelected: { habit in
                        selectedHabitForStats = habit
                    }
                )
            }
        }
    }
    
    // MARK: - Habit Views
    
    private var habitList: some View {
        LazyVStack(spacing: 12) {
            ForEach(activeHabitsForDate) { habit in
                HabitRowView(habit: habit, date: selectedDate, onTap: {
                    selectedHabit = habit
                })
                .contextMenu {
                    Button {
                        if !habit.isCompletedForDate(selectedDate) {
                            actionService.completeHabit(habit, for: selectedDate)
                        }
                    } label: {
                        Label("complete".localized, systemImage: "checkmark")
                    }
                    .disabled(habit.isCompletedForDate(selectedDate))
                    
                    Button {
                        actionService.addProgress(to: habit, for: selectedDate)
                    } label: {
                        Label("add_progress".localized, systemImage: "plus")
                    }
                    
                    Button {
                        actionService.editHabit(habit)
                    } label: {
                        Label("edit".localized, systemImage: "pencil")
                    }
                    
                    Button {
                        actionService.showStatistics(for: habit)
                    } label: {
                        Label("statistics".localized, systemImage: "chart.bar")
                    }
                    
                    Button {
                        isReorderingSheetPresented = true
                    } label: {
                        Label("reorder_habits".localized, systemImage: "list.number")
                    }
                    
                    Button(role: .destructive) {
                        actionService.deleteHabit(habit)
                    } label: {
                        Label("delete".localized, systemImage: "trash")
                    }
                }
                .id(habit.uuid)
            }
            .padding(.top, 12)
        }
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
            return "today".localized
        } else if isYesterday(date) {
            return "yesterday".localized
        } else {
            return DateFormatter.dayAndCapitalizedMonth(from: date)
        }
    }
}
