import Foundation

// Протокол для абстракции хранилища данных
protocol HabitDataStore {
    func saveHabit(_ habit: Habit) throws
    func updateHabit(_ habit: Habit) throws
    func deleteHabit(_ habit: Habit) throws
    func loadHabits() -> [Habit]
    func saveProgress(_ progress: HabitProgress) throws
    func getProgress(for habitId: UUID, on date: Date) -> HabitProgress?
    func getAllProgress(for habitId: UUID) -> [HabitProgress]
    func deleteAllProgress(for habitId: UUID)
    func cleanOldData(before date: Date)
}

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

// Переименовываем класс для ясности
class HabitStoreManager: ObservableObject {
    @Published private(set) var habits: [Habit] = []
    let dataStore: HabitDataStore
    
    init(dataStore: HabitDataStore = UserDefaultsHabitStore()) {
        self.dataStore = dataStore
        loadHabits()
    }
    
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        do {
            try dataStore.saveHabit(habit)
        } catch {
            print("Error saving habit: \(error)")
        }
    }
    
    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
            do {
                try dataStore.updateHabit(habit)
            } catch {
                print("Error updating habit: \(error)")
            }
        }
    }
    
    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        do {
            try dataStore.deleteHabit(habit)
            dataStore.deleteAllProgress(for: habit.id)
        } catch {
            print("Error deleting habit: \(error)")
        }
    }
    
    func saveProgress(for habit: Habit, value: Double, isCompleted: Bool, date: Date = Date()) {
        let progress = HabitProgress(
            habitId: habit.id,
            date: date,
            value: value,
            isCompleted: isCompleted
        )
        do {
            try dataStore.saveProgress(progress)
        } catch {
            print("Error saving progress: \(error)")
        }
    }
    
    func getProgress(for habit: Habit, on date: Date = Date()) -> HabitProgress? {
        dataStore.getProgress(for: habit.id, on: date)
    }
    
    func getAllProgress(for habit: Habit) -> [HabitProgress] {
        dataStore.getAllProgress(for: habit.id)
    }
    
    func cleanOldData(before date: Date) {
        dataStore.cleanOldData(before: date)
    }
    
    private func loadHabits() {
        habits = dataStore.loadHabits()
    }
}

// Конкретная реализация для UserDefaults
class UserDefaultsHabitStore: HabitDataStore {
    private let defaults = UserDefaults.standard
    private let habitsKey = "savedHabits"
    private let versionKey = "habitStoreVersion"
    private let currentVersion = 1
    private let statistics = HabitStatistics()
    
    enum StoreError: Error {
        case encodingFailed
        case decodingFailed
        case invalidVersion
    }
    
    init() {
        migrateIfNeeded()
    }
    
    func saveHabit(_ habit: Habit) throws {
        var habits = loadHabits()
        habits.append(habit)
        try saveHabits(habits)
    }
    
    func updateHabit(_ habit: Habit) throws {
        var habits = loadHabits()
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
            try saveHabits(habits)
        }
    }
    
    func deleteHabit(_ habit: Habit) throws {
        var habits = loadHabits()
        habits.removeAll { $0.id == habit.id }
        try saveHabits(habits)
    }
    
    func loadHabits() -> [Habit] {
        guard let data = defaults.data(forKey: habitsKey) else { return [] }
        
        do {
            return try JSONDecoder().decode([Habit].self, from: data)
        } catch {
            print("Error loading habits: \(error)")
            return []
        }
    }
    
    func saveProgress(_ progress: HabitProgress) throws {
        statistics.saveProgress(progress)
    }
    
    func getProgress(for habitId: UUID, on date: Date) -> HabitProgress? {
        statistics.getProgress(for: habitId, on: date)
    }
    
    func getAllProgress(for habitId: UUID) -> [HabitProgress] {
        statistics.getAllProgress(for: habitId)
    }
    
    func deleteAllProgress(for habitId: UUID) {
        statistics.deleteAllProgress(for: habitId)
    }
    
    func cleanOldData(before date: Date) {
        statistics.cleanOldProgress(olderThan: date)
    }
    
    private func saveHabits(_ habits: [Habit]) throws {
        do {
            let encoded = try JSONEncoder().encode(habits)
            defaults.set(encoded, forKey: habitsKey)
            defaults.set(currentVersion, forKey: versionKey)
        } catch {
            throw StoreError.encodingFailed
        }
    }
    
    private func migrateIfNeeded() {
        let version = defaults.integer(forKey: versionKey)
        if version == 0 || version < currentVersion {
            defaults.set(currentVersion, forKey: versionKey)
        }
    }
}

private extension Calendar {
    func date(byAddingDays days: Int, to date: Date) -> Date? {
        return self.date(byAdding: .day, value: days, to: date)
    }
}
