import Foundation
import SwiftData

@Model
final class Habit {
    @Attribute(.unique) var uuid: UUID
    
    // Basic properties
    var title: String
    var type: HabitType
    var goal: Int // Target value (count or seconds for time)
    var iconName: String? // Иконка привычки
    
    // System properties
    var createdAt: Date
    
    // Relationship with completions (one-to-many)
    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion]
    
    // Settings for days and reminders
    var activeDaysBitmask: Int
    
    // ИЗМЕНЕНИЕ: вместо одного reminderTime теперь массив
    var reminderTimes: [Date]?
    var startDate: Date
    
    // Computed property for compatibility with existing UI
    var activeDays: [Bool] {
        get {
            let orderedWeekdays = Weekday.orderedByUserPreference
            return orderedWeekdays.map { isActive(on: $0) }
        }
        set {
            let orderedWeekdays = Weekday.orderedByUserPreference
            activeDaysBitmask = 0
            for (index, isActive) in newValue.enumerated() where index < 7 {
                if isActive {
                    let weekday = orderedWeekdays[index]
                    setActive(true, for: weekday)
                }
            }
        }
    }
    
    // MARK: - Методы для работы с активными днями
    
    // Проверить активен ли конкретный день недели
    func isActive(on weekday: Weekday) -> Bool {
        return (activeDaysBitmask & (1 << weekday.rawValue)) != 0
    }

    // Изменить активность конкретного дня недели
    func setActive(_ active: Bool, for weekday: Weekday) {
        if active {
            activeDaysBitmask |= (1 << weekday.rawValue)
        } else {
            activeDaysBitmask &= ~(1 << weekday.rawValue)
        }
    }

    // Проверить активен ли день для конкретной даты
    func isActiveOnDate(_ date: Date) -> Bool {
        let calendar = Calendar.userPreferred
        
        // Проверяем, что дата не раньше даты начала привычки
        let dateStartOfDay = calendar.startOfDay(for: date)
        let startDateOfDay = calendar.startOfDay(for: startDate)
        
        if dateStartOfDay < startDateOfDay {
            return false
        }
        
        // Проверяем, активен ли день недели
        let weekday = Weekday.from(date: date)
        return isActive(on: weekday)
    }
    
    // MARK: - Методы для работы с напоминаниями
    
    // ОБРАТНАЯ СОВМЕСТИМОСТЬ: для поддержки старого кода
    var reminderTime: Date? {
        get {
            return reminderTimes?.first
        }
        set {
            if let newTime = newValue {
                reminderTimes = [newTime]
            } else {
                reminderTimes = nil
            }
        }
    }
    
    // Добавить новое напоминание
    func addReminderTime(_ time: Date) {
        if reminderTimes == nil {
            reminderTimes = [time]
        } else {
            reminderTimes?.append(time)
        }
    }
    
    // Удалить напоминание
    func removeReminderTime(at index: Int) {
        guard var times = reminderTimes, times.count > index else { return }
        times.remove(at: index)
        reminderTimes = times.isEmpty ? nil : times
    }
    
    // Обновить напоминание
    func updateReminderTime(_ time: Date, at index: Int) {
        guard var times = reminderTimes, times.count > index else { return }
        times[index] = time
        reminderTimes = times
    }
    
    // Проверка наличия напоминаний
    var hasReminders: Bool {
        return reminderTimes != nil && !(reminderTimes?.isEmpty ?? true)
    }
    
    // MARK: - Методы для работы с прогрессом
    
    // Get progress for specific date
    func progressForDate(_ date: Date) -> Int {
        let calendar = Calendar.current
        return completions
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .reduce(0) { $0 + $1.value }
    }
    
    // FormattedProgress
    func formattedProgress(for date: Date) -> String {
        let progress = progressForDate(date)
        
        switch type {
        case .count:
            return progress.formattedAsProgress(total: goal)
        case .time:
            return progress.formattedAsTime()
        }
    }

    // FormattedGoal
    var formattedGoal: String {
        switch type {
        case .count:
            return "\(goal) \("times".localized)"
        case .time:
            let hours = goal / 3600
            let minutes = (goal % 3600) / 60
            if hours > 0 {
                return "hours_minutes_format".localized(with: hours, minutes)
            } else {
                return "minutes_format".localized(with: minutes)
            }
        }
    }
    
    // Check if habit is completed for the day
    func isCompletedForDate(_ date: Date) -> Bool {
        return progressForDate(date) >= goal
    }
    
    // Check if habit is exceeded for the day
    func isExceededForDate(_ date: Date) -> Bool {
        return progressForDate(date) > goal
    }
    
    // Get formatted progress value for specific date
    func formattedProgressValue(for date: Date) -> String {
        let progress = progressForDate(date)
        
        switch type {
        case .count:
            return progress.formattedAsProgressForRing()
        case .time:
            return progress.formattedAsTimeForRing()
        }
    }
    
    // Calculate completion percentage for the day
    func completionPercentageForDate(_ date: Date) -> Double {
        let progress = min(progressForDate(date), 999999)
        
        if goal <= 0 {
            return progress > 0 ? 1.0 : 0.0
        }
        
        let percentage = Double(progress) / Double(goal)
        return min(percentage, 1.0) // Cap at 100%
    }
    
    // Add progress value
    func addProgress(_ value: Int, for date: Date = .now) {
        let completion = HabitCompletion(date: date, value: value, habit: self)
        completions.append(completion)
    }
    
    // MARK: - Инициализаторы и обновление
    
    // Helper to create active days bitmask
    static func createDefaultActiveDaysBitMask() -> Int {
        return 0b1111111 // All days active
    }
    
    // Computed property for string ID
    var id: String {
        return uuid.uuidString
    }
    
    // Initializer with default values
    init(
        title: String,
        type: HabitType = .count,
        goal: Int = 0,
        iconName: String? = nil,
        createdAt: Date = .now,
        activeDays: [Bool]? = nil,
        reminderTimes: [Date]? = nil,  // ИЗМЕНЕНИЕ: теперь массив
        startDate: Date = .now
    ) {
        self.uuid = UUID()
        self.title = title
        self.type = type
        self.goal = goal
        self.iconName = iconName
        self.createdAt = createdAt
        self.completions = []
        
        if let days = activeDays {
            let orderedWeekdays = Weekday.orderedByUserPreference
            var bitmask = 0
            for (index, isActive) in days.enumerated() where index < 7 {
                if isActive {
                    let weekday = orderedWeekdays[index]
                    bitmask |= (1 << weekday.rawValue)
                }
            }
            self.activeDaysBitmask = bitmask
        } else {
            self.activeDaysBitmask = Habit.createDefaultActiveDaysBitMask()
        }
        
        self.reminderTimes = reminderTimes
        self.startDate = Calendar.current.startOfDay(for: startDate)
    }
    
    // СОВМЕСТИМОСТЬ: конструктор с одним reminderTime
    convenience init(
        title: String,
        type: HabitType = .count,
        goal: Int = 0,
        iconName: String? = nil,
        createdAt: Date = .now,
        activeDays: [Bool]? = nil,
        reminderTime: Date? = nil,  // Один reminderTime для совместимости
        startDate: Date = .now
    ) {
        let reminderTimesArray: [Date]? = reminderTime != nil ? [reminderTime!] : nil
        
        self.init(
            title: title,
            type: type,
            goal: goal,
            iconName: iconName,
            createdAt: createdAt,
            activeDays: activeDays,
            reminderTimes: reminderTimesArray,
            startDate: startDate
        )
    }
    
    // MARK: - Методы обновления свойств
    
    func update(
        title: String,
        type: HabitType,
        goal: Int,
        iconName: String?,
        activeDays: [Bool],
        reminderTimes: [Date]?,  // ИЗМЕНЕНИЕ: теперь массив
        startDate: Date
    ) {
        self.title = title
        self.type = type
        self.goal = goal
        self.iconName = iconName
        self.activeDays = activeDays
        self.reminderTimes = reminderTimes
        self.startDate = startDate
    }
    
    // СОВМЕСТИМОСТЬ: обновление с одним reminderTime
    func update(
        title: String,
        type: HabitType,
        goal: Int,
        iconName: String?,
        activeDays: [Bool],
        reminderTime: Date?,  // Один reminderTime для совместимости
        startDate: Date
    ) {
        let reminderTimesArray: [Date]? = reminderTime != nil ? [reminderTime!] : nil
        update(
            title: title,
            type: type,
            goal: goal,
            iconName: iconName,
            activeDays: activeDays,
            reminderTimes: reminderTimesArray,
            startDate: startDate
        )
    }
}
