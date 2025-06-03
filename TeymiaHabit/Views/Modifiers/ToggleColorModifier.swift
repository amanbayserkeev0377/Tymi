import SwiftUI

struct ToggleColorModifier: ViewModifier {
    @ObservedObject private var colorManager = AppColorManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .tint(
                colorManager.selectedColor == .primary && colorScheme == .dark
                    ? .gray.opacity(0.8)
                    : colorManager.selectedColor.color
            )
    }
}

extension View {
    func withToggleColor() -> some View {
        modifier(ToggleColorModifier())
    }
}
