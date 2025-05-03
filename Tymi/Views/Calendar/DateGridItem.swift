import Foundation

struct DateGridItem: Identifiable, Hashable {
    let id = UUID()
    let date: Date?
    let index: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DateGridItem, rhs: DateGridItem) -> Bool {
        return lhs.id == rhs.id
    }
}
