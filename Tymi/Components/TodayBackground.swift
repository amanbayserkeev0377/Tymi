import SwiftUI

struct TodayBackground: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        LinearGradient(
            colors: colorScheme == .light
                ? [
                    Color(red: 0.83, green: 0.81, blue: 0.99),
                    Color(red: 0.97, green: 0.81, blue: 0.89),
                    Color(red: 0.91, green: 0.83, blue: 0.85)
                  ]
                : [
                    Color(red: 0.15, green: 0.12, blue: 0.2),
                    Color(red: 0.2, green: 0.15, blue: 0.18)
                  ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
