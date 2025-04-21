import SwiftUI

struct TodayViewBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private var lightThemeColors: [Color] = [
        Color(hex: "#F8F9FA"),
        Color(hex: "#E9ECEF"),
        Color(hex: "#DEE2E6")
    ]
    
    private var darkThemeColors: [Color] = [
        Color(hex: "#212529"),
        Color(hex: "#343A40"),
        Color(hex: "#495057")
    ]
    
    private var gradientColors: [Color] {
        colorScheme == .dark ? darkThemeColors : lightThemeColors
    }
    
    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview {
    ZStack {
        TodayViewBackground()
        
        Text("Сегодня")
            .font(.largeTitle)
            .fontWeight(.bold)
    }
}
