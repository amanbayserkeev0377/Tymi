import Foundation

struct Reminder: Codable, Equatable {
    var time: Date
    var isEnabled: Bool
    
    init(time: Date = Date(), isEnabled: Bool = false) {
        self.time = time
        self.isEnabled = isEnabled
    }
} 