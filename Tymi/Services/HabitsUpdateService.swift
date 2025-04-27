import Foundation
import SwiftUI

class HabitsUpdateService: ObservableObject {
    @Published var lastUpdateTimestamp: Date = Date()
    
    func triggerUpdate() {
        lastUpdateTimestamp = Date()
    }
} 