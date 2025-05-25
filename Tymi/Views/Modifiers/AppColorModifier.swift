import SwiftUI

struct AppColorModifier: ViewModifier {
    @ObservedObject private var colorManager = AppColorManager.shared
    
    func body(content: Content) -> some View {
        content
            .tint(colorManager.selectedColor.color)
    }
}

extension View {
    func withAppColor() -> some View {
        modifier(AppColorModifier())
    }
} 