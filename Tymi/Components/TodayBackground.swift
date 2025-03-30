import SwiftUI

struct TodayBackground: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        LinearGradient(
            colors: colorScheme == .light
                ? [
                    Color(red: 0.88, green: 0.89, blue: 1.0),
                    Color(red: 0.96, green: 0.89, blue: 0.94),
                    Color(red: 1.0, green: 0.92, blue: 0.85)
                  ]
                : [
                    Color(red: 0.06, green: 0.08, blue: 0.18),
                    Color(red: 0.14, green: 0.10, blue: 0.20),
                    Color(red: 0.22, green: 0.09, blue: 0.16)
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
