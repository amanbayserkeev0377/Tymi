import SwiftUI

struct ViewBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if colorScheme == .dark {
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.15, green: 0.15, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        } else {
            Color(red: 0.96, green: 0.96, blue: 0.98) // Нежный серо-фиолетовый как в Craft
                .ignoresSafeArea()
        }
    }
}

extension View {
    func withBackground() -> some View {
        self.background(ViewBackground())
    }
}

#Preview {
    VStack {
        Text("Light Mode")
            .preferredColorScheme(.light)
        Text("Dark Mode")
            .preferredColorScheme(.dark)
    }
    .withBackground()
}
