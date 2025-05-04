import SwiftUI
import SwiftData

struct TodayView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    @Query(filter: #Predicate<Habit> { !$0.isFreezed }, sort: \Habit.createdAt)
    private var baseHabits: [Habit]
    
    @State private var selectedDate: Date = .now
    @State private var isShowingNewHabitSheet = false
    @State private var selectedHabit: Habit? = nil
    @State private var isShowingCalendarSheet = false
    @State private var isShowingSettingsSheet = false
    @StateObject private var habitsUpdateService = HabitsUpdateService()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMM")
        return formatter
    }()
    
    // Активные привычки для выбранной даты
    private var activeHabitsForDate: [Habit] {
        baseHabits.filter { $0.isActiveOnDate(selectedDate) && selectedDate >= $0.startDate }
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
                TodayViewBackground()
                
                VStack {
                    ScrollView {
                        VStack(spacing: 0) {
                            if baseHabits.isEmpty {
                                // Нет привычек вообще
                                EmptyStateView()
                            } else {
                                // Кольцо прогресса отображается всегда
                                DailyProgressRing(date: selectedDate)
                                    .environmentObject(habitsUpdateService)
                                    .padding(.top, 16)
                                
                                // Список привычек для выбранной даты
                                if hasHabitsForDate {
                                    VStack(spacing: 12) {
                                        ForEach(activeHabitsForDate) { habit in
                                            HabitRowView(
                                                habit: habit,
                                                date: selectedDate,
                                                onTap: {
                                                    selectedHabit = habit
                                                }
                                            )
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
                                
                                // Добавляем пространство внизу для кнопки добавления
                                Spacer(minLength: 100)
                            }
                        }
                    }
                }
                
                // AddFloatingButton - всегда в том же месте
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        AddFloatingButton(action: { isShowingNewHabitSheet = true })
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle(formattedNavigationTitle(for: selectedDate))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        isShowingSettingsSheet = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                    .tint(.primary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isShowingCalendarSheet = true
                    }) {
                        Image(systemName: "calendar")
                    }
                    .tint(.primary)
                }
            }
            .sheet(isPresented: $isShowingNewHabitSheet) {
                NewHabitView()
                    .presentationBackground {
                        ZStack {
                            Rectangle().fill(.ultraThinMaterial)
                            if colorScheme != .dark {
                                Color.white.opacity(0.6)
                            }
                        }
                    }
            }
            .sheet(isPresented: $isShowingCalendarSheet) {
                CalendarView(selectedDate: $selectedDate)
                    .presentationDetents([.fraction(0.7)])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(40)
                    .presentationBackground {
                        let cornerRadius: CGFloat = 40
                        ZStack {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(.ultraThinMaterial)
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(
                                    colorScheme == .dark
                                    ? Color.white.opacity(0.1)
                                    : Color.black.opacity(0.15),
                                    lineWidth: 1.5
                                )
                        }
                    }
            }
            .sheet(isPresented: $isShowingSettingsSheet) {
                SettingsView()
                    .presentationDetents([.fraction(0.8)])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(40)
                    .presentationBackground {
                        let cornerRadius: CGFloat = 40
                        ZStack {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(.ultraThinMaterial)
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(
                                    colorScheme == .dark
                                    ? Color.white.opacity(0.1)
                                    : Color.black.opacity(0.15),
                                    lineWidth: 1.5
                                )
                        }
                    }
            }
            .sheet(item: $selectedHabit) { habit in
                HabitDetailView(habit: habit, date: selectedDate)
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
                                .stroke(
                                    colorScheme == .dark
                                    ? Color.white.opacity(0.1)
                                    : Color.black.opacity(0.15),
                                    lineWidth: 1.5
                                )
                        }
                    }
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

#Preview {
    TodayView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
