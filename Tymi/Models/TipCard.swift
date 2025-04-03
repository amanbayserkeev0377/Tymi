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

// Hex color extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 
