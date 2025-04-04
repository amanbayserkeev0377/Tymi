import SwiftUI

struct TipCard: Identifiable {
    var id = UUID()
    var title: String
    var subtitle: String
    var icon: String
    var gradient: [Color]
}

// Sample data
extension TipCard {
    static let tips: [TipCard] = [
        TipCard(
            title: "Atomic Habits",
            subtitle: "Small changes lead to remarkable results. Start with tiny improvements.",
            icon: "atom",
            gradient: [Color(hex: "9F2B68"), Color(hex: "3B3B98")]
        ),
        TipCard(
            title: "Stay Consistent",
            subtitle: "Motivation gets you started, habits keep you going. Never miss twice.",
            icon: "sparkles",
            gradient: [Color(hex: "FF6B6B"), Color(hex: "4ECDC4")]
        ),
        TipCard(
            title: "Identity First",
            subtitle: "Focus on who you wish to become. Your habits shape your identity.",
            icon: "person.crop.circle",
            gradient: [Color(hex: "45B649"), Color(hex: "DCE35B")]
        ),
        TipCard(
            title: "Environment Matters",
            subtitle: "Design your space for success. Make good habits obvious and easy.",
            icon: "leaf",
            gradient: [Color(hex: "614385"), Color(hex: "516395")]
        )
    ]
}
