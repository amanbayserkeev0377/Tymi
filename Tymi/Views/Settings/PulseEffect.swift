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
            .onChange(of: isSelected) { oldValue, newValue in
                if newValue && !isAnimating {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isAnimating = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isAnimating = false
                        }
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