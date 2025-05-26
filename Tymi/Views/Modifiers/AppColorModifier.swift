import SwiftUI

struct AppColorModifier: ViewModifier {
    @ObservedObject private var colorManager = AppColorManager.shared
    
    func body(content: Content) -> some View {
        content
            .tint(colorManager.selectedColor.color)
    }
}

// Новые модификаторы для селективного применения
struct AppTintModifier: ViewModifier {
    @ObservedObject private var colorManager = AppColorManager.shared
    
    func body(content: Content) -> some View {
        content
            .tint(colorManager.selectedColor.color)
    }
}

struct AppAccentModifier: ViewModifier {
    @ObservedObject private var colorManager = AppColorManager.shared
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle(colorManager.selectedColor.color)
    }
}

extension View {
    // Глобальная тонировка (восстанавливаем)
    func withAppColor() -> some View {
        modifier(AppColorModifier())
    }
    
    // Селективные модификаторы (для будущего использования)
    func withAppTint() -> some View {
        modifier(AppTintModifier())
    }
    
    func withAppAccent() -> some View {
        modifier(AppAccentModifier())
    }
}
