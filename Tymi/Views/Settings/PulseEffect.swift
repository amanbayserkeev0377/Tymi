import SwiftUI

struct PulseEffect: ViewModifier {
    let isSelected: Bool
    
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor, lineWidth: isSelected ? 2 : 0)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .opacity(isAnimating ? 0 : 1)
            )
            .onChange(of: isSelected) { newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isAnimating = true
                    }
                    
                    withAnimation(.easeInOut(duration: 0.3).delay(0.15)) {
                        isAnimating = false
                    }
                }
            }
    }
}

extension View {
    func pulseEffect(isSelected: Bool) -> some View {
        modifier(PulseEffect(isSelected: isSelected))
    }
} 