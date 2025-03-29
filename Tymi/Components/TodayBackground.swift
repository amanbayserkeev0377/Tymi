import SwiftUI

struct TodayBackground: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        LinearGradient(
            colors: colorScheme == .light
                ? [Color(red: 0.8, green: 0.6, blue: 0.9), Color(red: 0.9, green: 0.6, blue: 0.8)]
                : [Color(red: 0.1, green: 0.2, blue: 0.3), Color(red: 0.3, green: 0.1, blue: 0.2)],
            startPoint: .topLeading
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}