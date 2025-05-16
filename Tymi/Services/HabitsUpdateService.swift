import SwiftUI

@Observable
final class HabitsUpdateService {
    var lastUpdateTimestamp: Date = Date()
    
    func triggerUpdate() {
        lastUpdateTimestamp = Date()
    }
    
    @MainActor
    func triggerDelayedUpdate(delay: TimeInterval = 0.5) async {
        try? await Task.sleep(for: .seconds(delay))
        lastUpdateTimestamp = Date()
    }
}
