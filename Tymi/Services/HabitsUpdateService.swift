import SwiftUI

@Observable
final class HabitsUpdateService {
    var lastUpdateTimestamp: Date = Date()
    
    func triggerUpdate() {
        lastUpdateTimestamp = Date()
    }
    
    func triggerDelayedUpdate(delay: TimeInterval = 0.5) {
        // Используем более современный подход с Task
        Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(delay))
                lastUpdateTimestamp = Date()
            } catch {
                // Задача отменена
            }
        }
    }
}
