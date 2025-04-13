import SwiftUI

struct ViewBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if colorScheme == .dark {
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.13, blue: 0.13),
                    Color(red: 0.12, green: 0.11, blue: 0.14),
                    Color(red: 0.12, green: 0.11, blue: 0.17)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea()
        } else {
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.95, blue: 0.96),
                    Color(red: 0.98, green: 0.96, blue: 0.97),
                    Color(red: 0.96, green: 0.94, blue: 0.94)
                    
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}

extension View {
    func withBackground() -> some View {
        self.background(ViewBackground())
    }
}

#Preview("Light Theme") {
    ViewBackground()
        .environment(\.colorScheme, .light)
}

#Preview("Dark Theme") {
    ViewBackground()
        .environment(\.colorScheme, .dark)
}
