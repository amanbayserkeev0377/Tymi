import SwiftUI
import SwiftData

@Observable class ProgressStateManager {
    private(set) var progressCache: [Date: Double] = [:]
    private(set) var lastUpdateTimestamp: Date = Date()
    
    func updateProgress(for date: Date, value: Double) {
        progressCache[date] = value
        lastUpdateTimestamp = Date()
    }
    
    func getProgress(for date: Date) -> Double {
        return progressCache[date] ?? 0
    }
    
    func clear() {
        progressCache.removeAll()
        lastUpdateTimestamp = Date()
    }
    
    func refresh() {
        // Просто обновляем timestamp для триггера обновления UI
        lastUpdateTimestamp = Date()
    }
}
