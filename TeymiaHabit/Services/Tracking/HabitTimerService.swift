import SwiftUI
import SwiftData

@Observable
final class HabitTimerService: ProgressTrackingService {
    static let shared = HabitTimerService()
    
    // MARK: - Properties
    private(set) var progressUpdates: [String: Int] = [:]
    private var activeHabitId: String? = nil
    private var startTime: Date? = nil
    private var timer: Timer?
    
    // MARK: - Initialization
    private init() {
        // Don't load any state on init - keep it simple
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Timer Management
    private func startUITimer() {
        // Stop current timer if exists
        timer?.invalidate()
        timer = nil
        
        // Start timer only for UI updates
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // If no active timer, stop UI timer
            if self.activeHabitId == nil {
                self.timer?.invalidate()
                self.timer = nil
            }
        }
        
        // Add timer to common run loop for more reliable operation
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    // MARK: - ProgressTrackingService Implementation
    func getCurrentProgress(for habitId: String) -> Int {
        // Base progress (saved)
        let baseProgress = progressUpdates[habitId] ?? 0
        
        // If this timer is active, add elapsed time since start
        if activeHabitId == habitId, let startTime = startTime {
            let elapsed = Int(Date().timeIntervalSince(startTime))
            return baseProgress + elapsed
        }
        
        return baseProgress
    }
    
    func isTimerRunning(for habitId: String) -> Bool {
        return activeHabitId == habitId
    }
    
    func startTimer(for habitId: String, initialProgress: Int = 0) {
        print("🟢 Starting timer for \(habitId) with initial progress: \(initialProgress)")
        
        // If timer is already active for this habit, just exit
        if activeHabitId == habitId {
            print("🟢 Timer already running for \(habitId)")
            return
        }
        
        // If there's another active timer, stop it first
        if let activeId = activeHabitId, activeId != habitId {
            stopTimer(for: activeId)
        }
        
        // Set base progress and timer state
        progressUpdates[habitId] = initialProgress
        activeHabitId = habitId
        startTime = Date()
        
        // Start UI timer
        if timer == nil {
            startUITimer()
        }
        
        print("🟢 Timer started for \(habitId)")
    }
    
    func stopTimer(for habitId: String) {
        print("🔴 Stopping timer for \(habitId)")
        
        // Check that this is the active timer
        guard activeHabitId == habitId, let startTime = startTime else {
            print("🔴 Timer not active for \(habitId)")
            return
        }
        
        // Calculate elapsed time since start
        let elapsed = Int(Date().timeIntervalSince(startTime))
        
        // Add elapsed time to saved progress
        if elapsed > 0 {
            let currentProgress = progressUpdates[habitId] ?? 0
            progressUpdates[habitId] = currentProgress + elapsed
            print("🔴 Updated progress: \(currentProgress) + \(elapsed) = \(progressUpdates[habitId] ?? 0)")
        }
        
        // Clear active timer state
        activeHabitId = nil
        self.startTime = nil
        
        // Stop UI timer if no active timers
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        
        print("🔴 Timer stopped for \(habitId)")
    }
    
    func addProgress(_ value: Int, for habitId: String) {
        print("➕ Adding \(value) to habit \(habitId)")
        
        // If timer is active for this habit, stop it first
        if activeHabitId == habitId {
            stopTimer(for: habitId)
        }
        
        // Add value to progress
        let current = progressUpdates[habitId] ?? 0
        progressUpdates[habitId] = max(0, current + value)
        
        print("➕ New total for \(habitId): \(progressUpdates[habitId] ?? 0)")
    }
    
    func resetProgress(for habitId: String) {
        print("🔄 Resetting progress for \(habitId)")
        
        // Stop timer if running for this habit
        if activeHabitId == habitId {
            activeHabitId = nil
            startTime = nil
            
            // Stop UI timer
            if timer != nil {
                timer?.invalidate()
                timer = nil
            }
        }
        
        // Reset progress
        progressUpdates[habitId] = 0
        
        print("🔄 Progress reset for \(habitId)")
    }
    
    // MARK: - Public Methods для управления состоянием
    
    /// This method is now a no-op since we don't stop timers in background
    func stopAllTimers() {
        print("🔴 stopAllTimers() called - but we don't stop timers in background anymore")
        // Don't actually stop timers - let them continue running
    }
    
    /// This method is now a no-op since timers continue running
    func restoreStateFromBackground() {
        print("🔄 restoreStateFromBackground() called - but timers never stopped")
        // Nothing to restore since timers kept running
    }
    
    /// Check if there are active timers
    var hasActiveTimers: Bool {
        return activeHabitId != nil
    }
}
