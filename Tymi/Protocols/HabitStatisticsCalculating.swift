import Foundation
import Combine

protocol HabitStatisticsCalculating: AnyObject {
    var currentStreak: Int { get }
    var bestStreak: Int { get }
    var completedCount: Int { get }
    
    func loadStatistics()
    func markCompleted(on date: Date)
    func saveProgress()
} 