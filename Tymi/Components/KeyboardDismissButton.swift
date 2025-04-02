import SwiftUI

struct KeyboardDismissButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let action: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: action) {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.body.weight(.medium))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .frame(width: 44, height: 36)
                    .background(
                        Color.white.opacity(colorScheme == .light ? 0.4 : 0)
                    )
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(radius: 4)
            }
            .padding(.trailing, 12)
            .padding(.bottom, 0) // Прижата к клавиатуре
        }
        .transition(
            .asymmetric(
                insertion: .opacity.combined(with: .offset(y: 10)),
                removal: .opacity.combined(with: .offset(y: 10))
            )
        )
        .animation(.easeInOut(duration: 0.25), value: UUID())
    }
}
