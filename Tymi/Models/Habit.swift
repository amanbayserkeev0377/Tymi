import Foundation

struct Habit: Identifiable, Codable {
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
}

class HabitStore: ObservableObject {
    @Published private(set) var habits: [Habit] = []
    private let defaults = UserDefaults.standard
    private let habitsKey = "savedHabits"
    
    init() {
        loadHabits()
    }
    
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        saveHabits()
    }
    
    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
            saveHabits()
        }
    }
    
    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        saveHabits()
    }
    
    private func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            defaults.set(encoded, forKey: habitsKey)
        }
    }
    
    private func loadHabits() {
        if let data = defaults.data(forKey: habitsKey),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        }
    }
}
