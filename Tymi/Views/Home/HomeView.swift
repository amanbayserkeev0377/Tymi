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
    @State private var habitToEdit: Habit? = nil
    @State private var isDeleteAlertPresented = false
    @State private var habitToDelete: Habit? = nil
    @State private var alertState = AlertState()
    @State private var habitForProgress: Habit? = nil
    
    init() {
        let container = try! ModelContainer(for: Habit.self, HabitCompletion.self)
        _actionService = State(initialValue: HabitActionService(
            modelContext: container.mainContext,
            habitsUpdateService: HabitsUpdateService()
        ))
    }
    
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
        // Используем уже конкретный BuilderAPI View вместо BodyBuilder
        NavigationStack {
            contentView
        }
    }
    
    // Перемещаем содержимое в отдельное свойство
    private var contentView: some View {
        ZStack {
            VStack {
                ScrollView {
                    VStack(spacing: 0) {
                        WeeklyCalendarView(selectedDate: $selectedDate)
                        
                        if baseHabits.isEmpty {
                            // Нет привычек вообще
                            EmptyStateView()
                        } else {
                            // Кольцо прогресса отображается всегда
                            DailyProgressRing(date: selectedDate)
                                .padding()
                            
                            // Список привычек для выбранной даты
                            if hasHabitsForDate {
                                habitList
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        // Используем типизированную функцию toolbar вместо generic
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text(formattedNavigationTitle(for: selectedDate))
                    .font(.headline.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
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
                    isShowingNewHabitSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                        )
                        .padding(4)
                }
            }
        }
        // Применяем остальные модификаторы
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
            .presentationDetents([
                .fraction(UIScreen.main.bounds.width <= 375 ? 0.85 : 0.7)
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
            NavigationStack {
                NewHabitView(habit: habit)
            }
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
            actionService.updateContext(modelContext)
            actionService.updateService(habitsUpdateService)
            actionService.setCallbacks(
                onHabitSelected: { habit in
                    selectedHabit = habit
                },
                onHabitEditSelected: { habit in
                    habitToEdit = habit
                },
                onHabitStatsSelected: { habit in
                    selectedHabitForStats = habit
                }
            )
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
    
    // MARK: - Habit Views
    private var habitList: some View {
        LazyVStack(spacing: 4) {
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
                        actionService.editHabit(habit)
                    } label: {
                        Label("edit".localized, systemImage: "pencil")
                    }
                    
                    Button {
                        actionService.showStatistics(for: habit)
                    } label: {
                        Label("statistics".localized, systemImage: "chart.line.text.clipboard")
                    }
                    
                    Button {
                        isReorderingSheetPresented = true
                    } label: {
                        Label("reorder".localized, systemImage: "list.bullet")
                    }
                    
                    Button(role: .destructive) {
                        habitForProgress = habit
                        alertState.isDeleteAlertPresented = true
                    } label: {
                        Label("delete".localized, systemImage: "trash")
                    }
                    .tint(.red)
                }
                .id(habit.uuid)
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
}
