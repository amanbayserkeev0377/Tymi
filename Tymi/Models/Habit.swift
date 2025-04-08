import Foundation

struct Habit: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var type: HabitType
    var goal: Double
    var startDate: Date
    var activeDays: Set<Int> // 1 = Monday, 7 = Sunday
    var reminderTime: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        type: HabitType,
        goal: Double,
        startDate: Date = Date(),
        activeDays: Set<Int> = Set(1...7),
        reminderTime: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.goal = goal
        self.startDate = startDate
        self.activeDays = activeDays
        self.reminderTime = reminderTime
    }
    
    static func == (lhs: Habit, rhs: Habit) -> Bool {
        lhs.id == rhs.id
    }
}

class HabitStoreManager: ObservableObject {
    @Published private(set) var habits: [Habit] = []
    private let userDefaultsService = UserDefaultsService()
    private let notificationService = NotificationService.shared
    
    init() {
        loadHabits()
        notificationService.requestAuthorization()
    }
    
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        saveHabits()
        if habit.reminderTime != nil {
            notificationService.scheduleNotification(for: habit)
        }
    }
    
    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            let oldHabit = habits[index]
            habits[index] = habit
            saveHabits()
            
            // Обновляем уведомления, если изменилось время напоминания
            if oldHabit.reminderTime != habit.reminderTime {
                if habit.reminderTime != nil {
                    notificationService.scheduleNotification(for: habit)
                } else {
                    notificationService.cancelNotifications(for: habit)
                }
            }
        }
    }
    
    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        saveHabits()
        notificationService.cancelNotifications(for: habit)
    }
    
    func saveProgress(for habit: Habit, value: Double, isCompleted: Bool, date: Date = Date()) {
        let progress = HabitProgress(
            habitId: habit.id,
            date: date,
            value: value,
            isCompleted: isCompleted
        )
        userDefaultsService.saveProgress(progress)
    }
    
    func getProgress(for habit: Habit, on date: Date = Date()) -> HabitProgress? {
        userDefaultsService.getProgress(for: habit.id, on: date)
    }
    
    func getAllProgress(for habit: Habit) -> [HabitProgress] {
        userDefaultsService.getAllProgress(for: habit.id)
    }
    
    func cleanOldData(before date: Date) {
        userDefaultsService.cleanOldProgress(olderThan: date)
    }
    
    private func loadHabits() {
        habits = userDefaultsService.loadHabits()
    }
    
    private func saveHabits() {
        userDefaultsService.saveHabits(habits)
    }
}

private extension Calendar {
    func date(byAddingDays days: Int, to date: Date) -> Date? {
        return self.date(byAdding: .day, value: days, to: date)
    }
}
