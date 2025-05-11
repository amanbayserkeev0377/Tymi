import SwiftUI

@Observable
final class HabitsUpdateService {
    var lastUpdateTimestamp: Date = Date()
    
    func triggerUpdate() {
        lastUpdateTimestamp = Date()
    }
    
    func triggerDelayedUpdate(delay: TimeInterval = 0.5) {
        lastUpdateTimestamp = Date()
    }
}
