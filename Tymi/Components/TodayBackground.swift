import SwiftUI

struct TodayBackground: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        LinearGradient(
            colors: colorScheme == .light
                ? [
                    Color(hex: "ddd6f3"),
                    Color.white.opacity(0.5),
                    Color(hex: "FFE4E1")
                ]
                : [
                    Color(red: 0.06, green: 0.08, blue: 0.18),
                    Color(red: 0.14, green: 0.10, blue: 0.20),
                    Color(red: 0.17, green: 0.09, blue: 0.16)
                  ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview("Light") {
    TodayBackground()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    TodayBackground()
        .preferredColorScheme(.dark)
}
