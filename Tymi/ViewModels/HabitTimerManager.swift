import Foundation
import Combine

class HabitTimerManager: ObservableObject {
    @Published var isRunning = false
    @Published var currentProgress: Int = 0
    @Published var elapsedTime: Int = 0 // Current timer time
    
    private var startTime: Date?
    private var timer: AnyCancellable?
    
    init(initialProgress: Int = 0) {
        self.currentProgress = initialProgress
    }
    
    func startTimer() {
        guard !isRunning else { return }
        
        isRunning = true
        startTime = Date()
        
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateProgress()
            }
    }
    
    func stopTimer() {
        guard isRunning, let start = startTime else { return }
        
        isRunning = false
        let elapsedTime = Int(Date().timeIntervalSince(start))
        currentProgress += elapsedTime
        self.elapsedTime = 0
        startTime = nil
        timer?.cancel()
    }
    
    func resetTimer() {
        isRunning = false
        currentProgress = 0
        elapsedTime = 0
        startTime = nil
        timer?.cancel()
    }
    
    func addProgress(_ value: Int) {
        let newValue = currentProgress + value
        if newValue >= 0 {
            currentProgress = newValue
        } else {
            currentProgress = 0
        }
    }
    
    private func updateProgress() {
        guard isRunning, let start = startTime else { return }
        
        // Update displayed time without changing currentProgress
        elapsedTime = Int(Date().timeIntervalSince(start))
    }
    
    // Get total progress (current + running timer)
    var totalProgress: Int {
        return currentProgress + (isRunning ? elapsedTime : 0)
    }
    
    deinit {
        timer?.cancel()
    }
}
