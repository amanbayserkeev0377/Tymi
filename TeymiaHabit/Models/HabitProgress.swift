import SwiftUI
import SwiftData

struct HabitProgress {
    let habitId: String
    let date: Date
    var value: Int
    
    var isDirty: Bool = false
}
