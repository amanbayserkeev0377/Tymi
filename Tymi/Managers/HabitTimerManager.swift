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
        accumulatedTime = 0
        endBackgroundTask()
        
        DispatchQueue.main.async { [weak self] in
            self?.onValueUpdate?(ValueType.time(self?.accumulatedTime ?? 0))
        }
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
        guard let startTime = startTime else { return }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        accumulatedTime = elapsedTime
        
        DispatchQueue.main.async { [weak self] in
            self?.onValueUpdate?(ValueType.time(self?.accumulatedTime ?? 0))
        }
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