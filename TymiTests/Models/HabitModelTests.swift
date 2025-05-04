import XCTest
import SwiftData
@testable import Tymi

final class HabitModelTests: XCTestCase {
    
    // MARK: - Habit Tests
    
    func testHabitActiveDays() throws {
        let orderedWeekdays = Weekday.orderedByUserPreference
        
        var activeDays = Array(repeating: false, count: 7)
        
        let activeDayIndices = [0, 2, 4, 6]
        for index in activeDayIndices {
            let dayIndex = orderedWeekdays.firstIndex(of: Weekday(rawValue: index)!)!
            activeDays[dayIndex] = true
        }
        
        let habit = Habit(title: "Test", activeDays: activeDays)
        
        // Проверяем конкретные дни недели
        XCTAssertTrue(habit.isActive(on: .sunday))
        XCTAssertFalse(habit.isActive(on: .monday))
        XCTAssertTrue(habit.isActive(on: .tuesday))
        XCTAssertFalse(habit.isActive(on: .wednesday))
        XCTAssertTrue(habit.isActive(on: .thursday))
        XCTAssertFalse(habit.isActive(on: .friday))
        XCTAssertTrue(habit.isActive(on: .saturday))
        
        // Проверяем установку активных дней
        var newActiveDays = Array(repeating: false, count: 7)
        let newActiveDayIndices = [1, 2, 3]
        for index in newActiveDayIndices {
            let dayIndex = orderedWeekdays.firstIndex(of: Weekday(rawValue: index)!)!
            newActiveDays[dayIndex] = true
        }
        
        habit.activeDays = newActiveDays
        
        XCTAssertFalse(habit.isActive(on: .sunday))
        XCTAssertTrue(habit.isActive(on: .monday))
        XCTAssertTrue(habit.isActive(on: .tuesday))
        XCTAssertTrue(habit.isActive(on: .wednesday))
        XCTAssertFalse(habit.isActive(on: .thursday))
    }
    
    func testHabitProgress() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        // Create habit
        let habit = Habit(title: "Test Progress", type: .count, goal: 5)
        
        // Add progress for today
        habit.addProgress(3, for: today)
        
        // Add progress for yesterday
        habit.addProgress(5, for: yesterday)
        
        // Check progress calculations
        XCTAssertEqual(habit.progressForDate(today), 3)
        XCTAssertEqual(habit.progressForDate(yesterday), 5)
        
        // Check completion status
        XCTAssertFalse(habit.isCompletedForDate(today))
        XCTAssertTrue(habit.isCompletedForDate(yesterday))
        
        // Add more progress to today
        habit.addProgress(3, for: today)
        XCTAssertEqual(habit.progressForDate(today), 6)
        XCTAssertTrue(habit.isCompletedForDate(today))
        XCTAssertTrue(habit.isExceededForDate(today))
    }
    
    func testStartDateFiltering() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        // Create habit with tomorrow as start date
        let habit = Habit(title: "Future Habit", startDate: tomorrow)
        
        // Check if habit is active on different dates
        XCTAssertFalse(habit.isActiveOnDate(today))
        XCTAssertFalse(habit.isActiveOnDate(yesterday))
        XCTAssertTrue(habit.isActiveOnDate(tomorrow))
    }
    
    // MARK: - HabitType Tests
    
    func testHabitTypeFormatting() {
        // Count type
        let countHabit = Habit(title: "Count Habit", type: .count, goal: 10)
        XCTAssertEqual(countHabit.formattedGoal, "10 times")
        
        // Time type (minutes only)
        let timeHabit1 = Habit(title: "Time Habit", type: .time, goal: 1800) // 30 minutes
        XCTAssertTrue(timeHabit1.formattedGoal.contains("30"))
        
        // Time type (hours and minutes)
        let timeHabit2 = Habit(title: "Time Habit", type: .time, goal: 5400) // 1h 30m
        XCTAssertTrue(timeHabit2.formattedGoal.contains("1"))
        XCTAssertTrue(timeHabit2.formattedGoal.contains("30"))
    }
    
    // MARK: - StatsManager Tests
    
    func testStreakCalculation() async throws {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!
        
        // Create habit
        let habit = Habit(title: "Streak Test", type: .count, goal: 1)
        
        // Complete for yesterday and today
        habit.addProgress(1, for: yesterday)
        habit.addProgress(1, for: today)
        
        // Create StatsManager with in-memory context
        let modelContext = ModelContext(ModelContainer.empty)
        
        // Выполняем код, изолированный в main actor
        let statsManager = await StatsManager(modelContext: modelContext)
        
        // Calculate stats
        let (currentStreak, bestStreak, totalCompletions) = await statsManager.calculateStats(for: habit)
        
        // Current streak should be 2
        XCTAssertEqual(currentStreak, 2)
        XCTAssertEqual(bestStreak, 2)
        XCTAssertEqual(totalCompletions, 2)
        
        // Break streak
        habit.addProgress(0, for: twoDaysAgo)
        
        // Calculate stats again
        let updatedStats = await statsManager.calculateStats(for: habit)
        
        // Current streak should still be 2 (today and yesterday)
        XCTAssertEqual(updatedStats.currentStreak, 2)
    }
}
