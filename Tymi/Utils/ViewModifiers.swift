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

// MARK: - DeleteHabitAlertModifier
struct DeleteHabitAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onDelete: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("This will permanently delete all data for this habit.", isPresented: $isPresented) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("Freeze it instead to keep your progress.")
            }
    }
}

extension View {
    func sectionCard() -> some View {
        self.modifier(SectionCardModifier())
    }
    
    func deleteHabitAlert(isPresented: Binding<Bool>, onDelete: @escaping () -> Void) -> some View {
        self.modifier(DeleteHabitAlertModifier(isPresented: isPresented, onDelete: onDelete))
    }
}
