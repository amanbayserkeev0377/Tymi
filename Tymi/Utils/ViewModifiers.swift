import SwiftUI

// MARK: - SectionCardModifier for NewHabitView
struct SectionCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.black.opacity(0.1) : Color.white.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(colorScheme == .dark
                                    ? Color.gray.opacity(0.1)
                                    : Color.gray.opacity(0.05),
                                    lineWidth: 1)
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
