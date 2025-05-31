import SwiftUI

// MARK: - Pro Gradient Colors
struct ProGradientColors {
    static let proGradient = LinearGradient(
        colors: [
            Color(#colorLiteral(red: 0.4925274849, green: 0.5225450397, blue: 0.9995061755, alpha: 1)),
            Color(#colorLiteral(red: 0.6020479798, green: 0.4322265685, blue: 0.9930816293, alpha: 1)),
            Color(#colorLiteral(red: 0.8248458505, green: 0.4217056334, blue: 0.8538249135, alpha: 1))
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let proGradientSimple = LinearGradient(
        colors: [
            Color(#colorLiteral(red: 0.4925274849, green: 0.5225450397, blue: 0.9995061755, alpha: 1)),
            Color(#colorLiteral(red: 0.6020479798, green: 0.4322265685, blue: 0.9930816293, alpha: 1)),
            Color(#colorLiteral(red: 0.8248458505, green: 0.4217056334, blue: 0.8538249135, alpha: 1))
        ],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )
    
    // Для текста/иконок - берем средний цвет
    static let proAccentColor = Color(#colorLiteral(red: 0.4497185946, green: 0.3515004218, blue: 0.7663930655, alpha: 1))
}

// MARK: - View Extension для удобства
extension View {
    func withProGradient() -> some View {
        self.background(ProGradientColors.proGradient)
    }
    
    func withProGradientSimple() -> some View {
        self.background(ProGradientColors.proGradientSimple)
    }
    
    func proGradientForeground() -> some View {
        self.foregroundStyle(ProGradientColors.proGradientSimple)
    }
}
