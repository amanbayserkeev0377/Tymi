import SwiftUI
import SwiftData

struct TodayView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    @Query(filter: #Predicate<Habit> { !$0.isFreezed }, sort: [SortDescriptor(\Habit.createdAt)])
    private var baseHabits: [Habit]
    
    @State private var selectedDate: Date = .now
    @State private var isShowingNewHabitSheet = false
    @State private var selectedHabit: Habit? = nil
    @State private var isShowingSettingsSheet = false
    @State private var habitsUpdateService = HabitsUpdateService()
    
    // Добавляем состояние для принудительного обновления
    @State private var forceViewUpdate: Bool = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMM")
        return formatter
    }()
    
    // Активные привычки для выбранной даты
    private var activeHabitsForDate: [Habit] {
        // Используем forceViewUpdate как триггер для перевычисления
        _ = forceViewUpdate
        
        // Применяем фильтрацию к базовым привычкам
        let activeHabits = baseHabits.filter { habit in
            let isActive = habit.isActiveOnDate(selectedDate)
            let isAfterStartDate = selectedDate >= habit.startDate
            
            // Для отладки
            print("Checking habit: \(habit.title)")
            print("  Is active on date: \(isActive)")
            print("  Is after start date: \(isAfterStartDate)")
            print("  Combined result: \(isActive && isAfterStartDate)")
            
            return isActive && isAfterStartDate
        }
        
        // Для отладки
        print("Total active habits for \(selectedDate): \(activeHabits.count)")
        
        return activeHabits
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
                                    .environment(habitsUpdateService)
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
                                    .id("habits-list-\(forceViewUpdate)") // Важно: это заставит SwiftUI пересоздать список
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
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .top, spacing: 0) {
                WeeklyCalendarView(selectedDate: $selectedDate)
                    .environment(habitsUpdateService)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        isShowingSettingsSheet = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                    .tint(.primary)
                }
                
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
            }
            .sheet(isPresented: $isShowingNewHabitSheet) {
                NewHabitView()
                    .environment(habitsUpdateService)
                    .presentationBackground {
                        ZStack {
                            Rectangle().fill(.ultraThinMaterial)
                            if colorScheme != .dark {
                                Color.white.opacity(0.6)
                            }
                        }
                    }
                    .onDisappear {
                        // При закрытии окна создания привычки обновляем привычки
                        refreshHabitsQuery()
                    }
            }
            .sheet(isPresented: $isShowingSettingsSheet) {
                SettingsView()
                    .environment(habitsUpdateService)
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
                    .environment(habitsUpdateService)
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
            .onChange(of: selectedDate) { oldValue, newValue in
                print("TodayView: Date changed from \(oldValue) to \(newValue)")
                
                // Вызываем немедленное обновление
                forceViewUpdate.toggle()
                
                // Также запускаем отложенное обновление через 100мс
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    forceViewUpdate.toggle()
                    
                    // Обновляем данные через сервис обновления
                    habitsUpdateService.triggerUpdate()
                    
                    // Добавляем еще одно обновление через 300мс для подстраховки
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        refreshHabitsQuery()
                    }
                }
            }
            .onChange(of: habitsUpdateService.lastUpdateTimestamp) { _, _ in
                // Обновляем представление при сигнале от сервиса обновления
                refreshHabitsQuery()
            }
            .onAppear {
                // При появлении представления обновляем список
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    refreshHabitsQuery()
                }
            }
        }
        .environment(habitsUpdateService)
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
    
    // Метод для принудительного обновления запроса привычек
    private func refreshHabitsQuery() {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { !$0.isFreezed },
            sortBy: [SortDescriptor(\Habit.createdAt)]
        )
        
        Task {
            do {
                // Выполняем запрос заново
                _ = try modelContext.fetch(descriptor)
                
                // Обновляем состояние для перерисовки интерфейса
                DispatchQueue.main.async {
                    forceViewUpdate.toggle()
                }
            } catch {
                print("Error refreshing habits: \(error)")
            }
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
