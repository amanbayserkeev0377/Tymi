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
                    Color(red: 0.92, green: 0.91, blue: 0.96),
                    Color(red: 0.93, green: 0.94, blue: 0.99),
                    Color(hex: "ddd6f3")
                    
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
