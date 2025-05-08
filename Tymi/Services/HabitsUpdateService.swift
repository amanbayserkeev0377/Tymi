import SwiftUI

@Observable
final class HabitsUpdateService {
    var lastUpdateTimestamp: Date = Date()
    
    func triggerDelayedUpdate(delay: TimeInterval = 0.5) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            self.lastUpdateTimestamp = Date()
        }
    }
    
    func triggerUpdate() {
        lastUpdateTimestamp = Date()
    }
}
