import Foundation
import Combine
import UIKit

final class HabitTimerManager: HabitTimerManaging {
    private let habit: Habit
    private let dataStore: HabitDataStore
    private var timer: Timer?
    private var accumulatedTime: TimeInterval = 0
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var wasRunningBeforeBackground = false
    private var lastUpdateTime: Date?
    
    var onValueUpdate: ((ValueType) -> Void)?
    private(set) var isPlaying: Bool = false
    private(set) var startTime: Date?
    
    init(habit: Habit, dataStore: HabitDataStore = UserDefaultsService.shared) {
        self.habit = habit
        self.dataStore = dataStore
        
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
    
    func start() {
        guard !isPlaying else { return }
        
        isPlaying = true
        startTime = Date()
        lastUpdateTime = startTime
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateValue()
        }
        
        RunLoop.main.add(timer!, forMode: .common)
        startBackgroundTask()
        
        updateValue()
    }
    
    func pause() {
        guard isPlaying else { return }
        
        isPlaying = false
        timer?.invalidate()
        timer = nil
        startTime = nil
        lastUpdateTime = nil
        accumulatedTime = 0
        endBackgroundTask()
        
        onValueUpdate?(ValueType.time(accumulatedTime))
    }
    
    func resumeIfNeeded() {
        guard habit.type == .time else { return }
        start()
    }
    
    func pauseIfNeeded() {
        guard habit.type == .time else { return }
        pause()
    }
    
    @objc func handleAppDidEnterBackground() {
        wasRunningBeforeBackground = isPlaying
        if isPlaying {
            pause()
        }
    }
    
    @objc func handleAppWillEnterForeground() {
        if wasRunningBeforeBackground {
            start()
        }
    }
    
    func cleanup() {
        pause()
        NotificationCenter.default.removeObserver(self)
        onValueUpdate = nil
    }
    
    private func updateValue() {
        guard let startTime = startTime,
              let lastUpdate = lastUpdateTime else { return }
        
        let currentTime = Date()
        let elapsedSinceLastUpdate = currentTime.timeIntervalSince(lastUpdate)
        lastUpdateTime = currentTime
        
        accumulatedTime += elapsedSinceLastUpdate
        
        let newValue = ValueType.time(accumulatedTime)
        onValueUpdate?(newValue)
        
        print("Timer updated, elapsedTime: \(accumulatedTime)")
    }
    
    private func startBackgroundTask() {
        endBackgroundTask()
        
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "TimerTask") { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
} 