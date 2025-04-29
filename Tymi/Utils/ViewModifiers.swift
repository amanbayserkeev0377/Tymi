import SwiftUI

// MARK: - SectionCardModifier
struct SectionCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.black.opacity(0.1) : Color.white.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(colorScheme == .dark
                                    ? Color.white.opacity(0.1)
                                    : Color.black.opacity(0.1),
                                    lineWidth: 0.5)
                    )
                    .shadow(radius: 0.5)
            )
            .padding(.horizontal)
    }
}

extension View {
    func sectionCard() -> some View {
        self.modifier(SectionCardModifier())
    }
}
