import SwiftUI
import SwiftData

struct HomeView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    
    @Query(sort: [SortDescriptor(\Habit.createdAt)])
    private var baseHabits: [Habit]
    
    @State private var selectedDate: Date = .now
    @State private var isShowingNewHabitSheet = false
    
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
    
    func formattedDate(_ date: Date) -> String {
        let weekday = DateFormatter.weekday.string(from: date).prefix(1).uppercased()
        + DateFormatter.weekday.string(from: date).dropFirst().lowercased()
        let day = DateFormatter.dayOfMonth.string(from: date)
        let month = DateFormatter.shortMonth.string(from: date).prefix(1).uppercased()
        + DateFormatter.shortMonth.string(from: date).dropFirst().lowercased()
        
        return "\(weekday), \(day) \(month)"
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    ScrollView {
                        VStack(spacing: 0) {
                            if baseHabits.isEmpty {
                                // Нет привычек вообще
                                EmptyStateView()
                            } else {
                                // Кольцо прогресса отображается всегда
                                DailyProgressRing(date: selectedDate)
                                    .padding(.top, 16)
                                
                                // Список привычек для выбранной даты
                                if hasHabitsForDate {
                                    VStack(spacing: 12) {
                                        ForEach(activeHabitsForDate) { habit in
                                            // Заменяем на NavigationLink
                                            NavigationLink(value: habit) {
                                                HabitRowView(
                                                    habit: habit,
                                                    date: selectedDate,
                                                    onTap: { } // onTap больше не нужен
                                                )
                                                .id(habit.uuid)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.top, 12)
                                } else {
                                    // Специальное сообщение, если нет привычек на выбранную дату
                                    // но при этом привычки в целом существуют
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
            .navigationBarTitleDisplayMode(.inline)
            // Добавляем navigationDestination для навигации к HabitDetailView
            .navigationDestination(for: Habit.self) { habit in
                HabitDetailView(
                    habit: habit,
                    date: selectedDate
                )
            }
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
            .onChange(of: selectedDate) { _, _ in
                habitsUpdateService.triggerUpdate()
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
            return "today".localized
        } else if isYesterday(date) {
            return "yesterday".localized
        } else {
            return formattedDate(date)
        }
    }
}
