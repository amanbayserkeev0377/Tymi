import Foundation
import Combine

final class HabitStatisticsCalculator: HabitStatisticsCalculating {
    private let habit: Habit
    private let dataStore: HabitDataStore
    
    private(set) var currentStreak: Int = 0
    private(set) var bestStreak: Int = 0
    private(set) var completedCount: Int = 0
    
    init(habit: Habit, dataStore: HabitDataStore = UserDefaultsService.shared) {
        self.habit = habit
        self.dataStore = dataStore
        loadStatistics()
    }
    
    func loadStatistics() {
        let allProgress = dataStore.getAllProgress(for: habit.id)
        let completedProgress = allProgress.filter { $0.isCompleted }
        
        completedCount = completedProgress.count
        currentStreak = calculateCurrentStreak(from: allProgress)
        bestStreak = calculateBestStreak(from: allProgress)
    }
    
    func markCompleted(on date: Date) {
        let progress = HabitProgress(
            habitId: habit.id,
            date: date,
            value: habit.goal.doubleValue,
            isCompleted: true
        )
        
        dataStore.saveProgress(progress)
        loadStatistics()
    }
    
    func saveProgress() {
        // Сохранение прогресса уже происходит в markCompleted
    }
    
    private func calculateCurrentStreak(from progress: [HabitProgress]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let sortedProgress = progress.sorted { $0.date > $1.date }
        
        guard !sortedProgress.isEmpty else { return 0 }
        
        let todayProgress = sortedProgress.first { calendar.isDate($0.date, inSameDayAs: today) }
        if let todayProgress = todayProgress, todayProgress.isCompleted {
            return calculateStreak(startingFrom: today, progress: sortedProgress)
        } else {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            let yesterdayProgress = sortedProgress.first { calendar.isDate($0.date, inSameDayAs: yesterday) }
            
            if let yesterdayProgress = yesterdayProgress, yesterdayProgress.isCompleted {
                return calculateStreak(startingFrom: yesterday, progress: sortedProgress)
            } else {
                return 0
            }
        }
    }
    
    private func calculateBestStreak(from progress: [HabitProgress]) -> Int {
        let calendar = Calendar.current
        
        let sortedProgress = progress.sorted { $0.date < $1.date }
        
        guard !sortedProgress.isEmpty else { return 0 }
        
        var bestStreak = 0
        var currentStreak = 0
        var currentDate: Date? = nil
        
        for progress in sortedProgress {
            let progressDate = calendar.startOfDay(for: progress.date)
            
            if currentDate == nil || calendar.isDate(progressDate, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: currentDate!)!) {
                if progress.isCompleted {
                    currentStreak += 1
                    bestStreak = max(bestStreak, currentStreak)
                } else {
                    currentStreak = 0
                }
                currentDate = progressDate
            }
        }
        
        return bestStreak
    }
    
    private func calculateStreak(startingFrom date: Date, progress: [HabitProgress]) -> Int {
        let calendar = Calendar.current
        var currentDate = date
        var streak = 0
        
        while true {
            let dayProgress = progress.first { calendar.isDate($0.date, inSameDayAs: currentDate) }
            
            if let dayProgress = dayProgress, dayProgress.isCompleted {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return streak
    }
} 