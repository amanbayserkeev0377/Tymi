import Foundation
import Combine

class HabitTimerManager: ObservableObject {
    @Published var isRunning = false
    @Published var currentProgress: Int = 0
    @Published var elapsedTime: Int = 0 // Current timer time
    @Published var totalProgress: Int = 0 // Total progress (current + elapsed)
    
    private var startTime: Date?
    private var timer: AnyCancellable?
    
    init(initialProgress: Int = 0) {
        self.currentProgress = initialProgress
        self.totalProgress = initialProgress
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
        totalProgress = currentProgress
        self.elapsedTime = 0
        startTime = nil
        timer?.cancel()
    }
    
    func resetTimer() {
        stopTimer() // Сначала останавливаем таймер, если он запущен
        currentProgress = 0
        totalProgress = 0
        elapsedTime = 0
    }
    
    func addProgress(_ value: Int) {
        // Останавливаем таймер перед изменением прогресса
        if isRunning {
            stopTimer()
        }
        
        let newValue = currentProgress + value
        if newValue >= 0 {
            currentProgress = newValue
            totalProgress = newValue
        } else {
            currentProgress = 0
            totalProgress = 0
        }
    }
    
    private func updateProgress() {
        guard isRunning, let start = startTime else { return }
        
        // Update displayed time without changing currentProgress
        elapsedTime = Int(Date().timeIntervalSince(start))
        totalProgress = currentProgress + elapsedTime
    }
    
    deinit {
        timer?.cancel()
    }
}
