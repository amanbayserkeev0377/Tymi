import SwiftUI

enum HabitIconColor: String, CaseIterable, Codable {
    case colorPicker = "colorPicker"
    case primary = "primary"
    case red = "red"
    case orange = "orange"
    case yellow = "yellow"
    case green = "green"
    case mint = "mint"
    case blue = "blue"
    case purple = "purple"
    case pink = "pink"
    case pink2 = "pink2"
    case brown = "brown"
    case gray = "gray"
    
    static var customColor: Color = .gray
    
    var color: Color {
        switch self {
        case .colorPicker: return Self.customColor
        case .primary: return .primary
        case .red: return Color(#colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1))
        case .orange: return Color(#colorLiteral(red: 1, green: 0.5781051517, blue: 0, alpha: 1))
        case .yellow: return Color(#colorLiteral(red: 1, green: 0.7529411765, blue: 0, alpha: 1))
        case .green: return Color(#colorLiteral(red: 0.1294117647, green: 0.5176470588, blue: 0.3882352941, alpha: 1))
        case .mint: return Color(#colorLiteral(red: 0, green: 0.6431372549, blue: 0.5490196078, alpha: 1))
        case .blue: return Color(#colorLiteral(red: 0.2745098039, green: 0.5098039216, blue: 0.7058823529, alpha: 1))
        case .purple: return Color(#colorLiteral(red: 0.6078431373, green: 0.3490196078, blue: 0.7137254902, alpha: 1))
        case .pink: return Color(#colorLiteral(red: 0.9098039216, green: 0.6392156863, blue: 0.6117647059, alpha: 1))
        case .pink2: return Color(#colorLiteral(red: 0.8705882353, green: 0.1921568627, blue: 0.3882352941, alpha: 1))
        case .brown: return Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))
        case .gray: return Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))
        }
    }
}

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
