import SwiftUI

@Observable @MainActor
final class HabitsUpdateService {
    var lastUpdateTimestamp: Date = Date()
    
    func triggerUpdate() {
        lastUpdateTimestamp = Date()
    }
    
    func triggerDelayedUpdate(delay: TimeInterval = 0.5) async {
        try? await Task.sleep(for: .seconds(delay))
        lastUpdateTimestamp = Date()
    }
}
