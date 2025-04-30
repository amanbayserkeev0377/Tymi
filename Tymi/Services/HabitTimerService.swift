import Foundation
import Combine
import UIKit

class HabitTimerService: ObservableObject {
    static let shared = HabitTimerService()
    
    private var timers: [String: Timer] = [:]
    private var progress: [String: Int] = [:]
    private var startTimes: [String: Date] = [:]
    private var backgroundTaskIdentifiers: [String: UIBackgroundTaskIdentifier] = [:]
    
    @Published private(set) var progressUpdates: [String: Int] = [:]
    
    private init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func handleAppDidEnterBackground() {
        for (habitId, _) in timers {
            if let startTime = startTimes[habitId] {
                let elapsedTime = Int(Date().timeIntervalSince(startTime))
                let newProgress = (progress[habitId] ?? 0) + elapsedTime
                progress[habitId] = newProgress
                progressUpdates[habitId] = newProgress
                
                let backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
                    self?.stopTimer(for: habitId)
                }
                backgroundTaskIdentifiers[habitId] = backgroundTask
            }
        }
    }
    
    @objc private func handleAppWillEnterForeground() {
        for (habitId, _) in timers {
            if let backgroundTask = backgroundTaskIdentifiers[habitId] {
                UIApplication.shared.endBackgroundTask(backgroundTask)
                backgroundTaskIdentifiers[habitId] = nil
            }
            
            if let startTime = startTimes[habitId] {
                let elapsedTime = Int(Date().timeIntervalSince(startTime))
                let newProgress = (progress[habitId] ?? 0) + elapsedTime
                progress[habitId] = newProgress
                progressUpdates[habitId] = newProgress
                startTimes[habitId] = Date()
            }
        }
    }
    
    func startTimer(for habitId: String, initialProgress: Int = 0) {
        stopTimer(for: habitId)
        
        progress[habitId] = initialProgress
        progressUpdates[habitId] = initialProgress
        startTimes[habitId] = Date()
        
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self,
                  let startTime = self.startTimes[habitId] else { return }
            
            let elapsedTime = Int(Date().timeIntervalSince(startTime))
            let newProgress = initialProgress + elapsedTime
            
            self.progress[habitId] = newProgress
            self.progressUpdates[habitId] = newProgress
        }
        
        RunLoop.main.add(timer, forMode: .common)
        timers[habitId] = timer
    }
    
    func stopTimer(for habitId: String) {
        timers[habitId]?.invalidate()
        timers[habitId] = nil
        
        startTimes[habitId] = nil
        
        if let backgroundTask = backgroundTaskIdentifiers[habitId] {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTaskIdentifiers[habitId] = nil
        }
    }
    
    func resetTimer(for habitId: String) {
        stopTimer(for: habitId)
        progress[habitId] = 0
        progressUpdates[habitId] = 0
    }
    
    func addProgress(_ value: Int, for habitId: String) {
        stopTimer(for: habitId)
        let newProgress = (progress[habitId] ?? 0) + value
        progress[habitId] = newProgress
        progressUpdates[habitId] = newProgress
    }
    
    func getCurrentProgress(for habitId: String) -> Int {
        return progress[habitId] ?? 0
    }
    
    func isTimerRunning(for habitId: String) -> Bool {
        return timers[habitId] != nil
    }
    
    func wasTimerRunning(for habitId: String) -> Bool {
        return startTimes[habitId] != nil
    }
    
    func restoreTimerState(for habitId: String) {
        if startTimes[habitId] != nil {
            startTimer(for: habitId, initialProgress: progress[habitId] ?? 0)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 