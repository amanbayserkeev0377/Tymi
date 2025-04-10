import Foundation

struct Habit: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: HabitType
    var goal: Double
    var startDate: Date
    var activeDays: Set<Int> // 1 = Monday, 7 = Sunday
    var reminders: [Reminder]
    var isArchived: Bool
    
    init(
        id: UUID = UUID(),
        name: String = "",
        type: HabitType = .count,
        goal: Double = 1,
        startDate: Date = Date(),
        activeDays: Set<Int> = Set(1...7),
        reminders: [Reminder] = [],
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.goal = goal
        self.startDate = startDate
        self.activeDays = activeDays
        self.reminders = reminders
        self.isArchived = isArchived
    }
}

enum HabitType: String, Codable, CaseIterable {
    case count
    case time
    
    var title: String {
        switch self {
        case .count:
            return "Count"
        case .time:
            return "Timer"
        }
    }
    
    var systemImage: String {
        switch self {
        case .count:
            return "number"
        case .time:
            return "timer"
        }
    }
}

enum Weekday: Int, CaseIterable, Codable {
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    case sunday = 7
    
    var shortName: String {
        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }
}

class HabitStoreManager: ObservableObject {
    @Published private(set) var habits: [Habit] = []
    private let userDefaultsService = UserDefaultsService()
    private let notificationService = NotificationService.shared
    
    init() {
        loadHabits()
    }
    
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        saveHabits()
        if habit.reminders.contains(where: { $0.isEnabled }) {
            notificationService.scheduleNotifications(for: habit)
        }
    }
    
    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            let oldHabit = habits[index]
            habits[index] = habit
            saveHabits()
            
            // Обновляем уведомления, если изменилось время напоминания
            if oldHabit.reminders.contains(where: { $0.isEnabled }) != habit.reminders.contains(where: { $0.isEnabled }) {
                if habit.reminders.contains(where: { $0.isEnabled }) {
                    notificationService.scheduleNotifications(for: habit)
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
