import Foundation

enum GoalValue: Codable {
    case count(Int32)
    case time(Double)
    
    // Реализация Codable
    enum CodingKeys: String, CodingKey {
        case type, countValue, timeValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "count":
            let value = try container.decode(Int32.self, forKey: .countValue)
            self = .count(value)
        case "time":
            let value = try container.decode(Double.self, forKey: .timeValue)
            self = .time(value)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid goal type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .count(let value):
            try container.encode("count", forKey: .type)
            try container.encode(value, forKey: .countValue)
        case .time(let value):
            try container.encode("time", forKey: .type)
            try container.encode(value, forKey: .timeValue)
        }
    }
    
    // Геттер для получения значения как Double (для совместимости)
    var doubleValue: Double {
        switch self {
        case .count(let value): return Double(value)
        case .time(let value): return value
        }
    }
}

struct Habit: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var type: HabitType
    var goal: GoalValue
    var startDate: Date
    var activeDays: Set<Int> // 1 = Sunday, 2 = Monday, ..., 7 = Saturday (Calendar.current.firstWeekday)
    var reminders: [Reminder]
    var isArchived: Bool
    
    init(
        id: UUID = UUID(),
        name: String = "",
        type: HabitType = .count,
        goal: GoalValue? = nil,
        startDate: Date = Date(),
        activeDays: Set<Int> = Set(1...7),
        reminders: [Reminder] = [],
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.goal = goal ?? (type == .count ? .count(1) : .time(1))
        self.startDate = startDate
        self.activeDays = activeDays
        self.reminders = reminders
        self.isArchived = isArchived
    }
    
    // Реализация Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Habit, rhs: Habit) -> Bool {
        lhs.id == rhs.id
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
