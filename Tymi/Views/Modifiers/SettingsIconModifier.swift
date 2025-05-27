import SwiftUI

struct SettingsIconModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    let lightColors: [Color]
    let fontSize: CGFloat
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle(
                colorScheme == .dark ?
                LinearGradient(
                    colors: lightColors,
                    startPoint: .top,
                    endPoint: .bottom
                ) :
                LinearGradient(colors: [.white, .white], startPoint: .top, endPoint: .bottom)
            )
            .font(.system(size: fontSize, weight: .medium))
            .frame(width: 29, height: 29)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(LinearGradient(
                        colors: colorScheme == .dark ? [
                            Color(#colorLiteral(red: 0.1882353127, green: 0.1882353127, blue: 0.1882353127, alpha: 1)),
                            Color(#colorLiteral(red: 0.08235292882, green: 0.08235292882, blue: 0.08235292882, alpha: 1))
                        ] : lightColors,
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(
                                colorScheme == .dark ?
                                Color.white.opacity(0.5) : Color.gray.opacity(0.5),
                                lineWidth: colorScheme == .dark ? 0.2 : 0.4
                            )
                    )
            )
    }
}

extension View {
    func withIOSSettingsIcon(
        lightColors: [Color],
        fontSize: CGFloat = 14
    ) -> some View {
        modifier(SettingsIconModifier(
            lightColors: lightColors,
            fontSize: fontSize
        ))
    }
}
