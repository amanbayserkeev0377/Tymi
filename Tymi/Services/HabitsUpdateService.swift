import Foundation
import SwiftUI
import Combine

class HabitsUpdateService: ObservableObject {
    @Published var lastUpdateTimestamp: Date = Date()
    
    func triggerDelayedUpdate(delay: TimeInterval = 0.5) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.lastUpdateTimestamp = Date()
        }
    }
    
    func triggerUpdate() {
        lastUpdateTimestamp = Date()
    }
}
