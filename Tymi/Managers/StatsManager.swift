import Foundation
import SwiftData

@MainActor
class StatsManager {
    // MARK: - Properties
    private let modelContext: ModelContext
    private let calendar = Calendar.current
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    func calculateStats(for habit: Habit, upTo date: Date = .now) -> (currentStreak: Int, bestStreak: Int, totalCompletions: Int) {
        let completions = habit.completions
            .filter { calendar.isDate($0.date, inSameDayAs: date) || $0.date < date }
            .sorted { $0.date > $1.date }
        
        let currentStreak = calculateCurrentStreak(habit: habit, completions: completions, upTo: date)
        let bestStreak = calculateBestStreak(habit: habit, completions: completions)
        let totalCompletions = calculateTotalCompletions(habit: habit, completions: completions)
        
        return (currentStreak, bestStreak, totalCompletions)
    }
    
    // MARK: - Private Methods
    private func calculateCurrentStreak(habit: Habit, completions: [HabitCompletion], upTo date: Date) -> Int {
        var streak = 0
        var currentDate = date
        
        while streak < 365 { // Ограничиваем максимальную длину серии
            let dayCompletions = completions.filter { calendar.isDate($0.date, inSameDayAs: currentDate) }
            
            if dayCompletions.isEmpty {
                if !habit.isActiveOnDate(currentDate) {
                    guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                        // Не удалось перейти к предыдущему дню, прерываем подсчет
                        break
                    }
                    currentDate = previousDay
                    continue
                }
                break
            }
            
            let totalProgress = dayCompletions.reduce(0) { $0 + $1.value }
            if totalProgress >= habit.goal {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    // Не удалось перейти к предыдущему дню, но серию уже учли
                    break
                }
                currentDate = previousDay
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateBestStreak(habit: Habit, completions: [HabitCompletion]) -> Int {
        var bestStreak = 0
        var currentStreak = 0
        var currentDate = Date()
        
        // Сортируем по дате в обратном порядке
        let sortedCompletions = completions.sorted { $0.date > $1.date }
        
        for completion in sortedCompletions {
            if calendar.isDate(completion.date, inSameDayAs: currentDate) {
                if completion.value >= habit.goal {
                    currentStreak += 1
                    bestStreak = max(bestStreak, currentStreak)
                } else {
                    currentStreak = 0
                }
            } else {
                currentStreak = 0
                currentDate = completion.date
            }
        }
        
        return bestStreak
    }
    
    private func calculateTotalCompletions(habit: Habit, completions: [HabitCompletion]) -> Int {
        var completedDays = Set<Date>()
        for completion in completions {
            if completion.value >= habit.goal {
                let day = calendar.startOfDay(for: completion.date)
                completedDays.insert(day)
            }
        }
        return completedDays.count
    }
} 
