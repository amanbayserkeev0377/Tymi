import SwiftUI

struct ProgressRing: View {
    let progress: Double
    let currentValue: String
    let isCompleted: Bool
    let isExceeded: Bool
    var size: CGFloat = 180
    var lineWidth: CGFloat = 24
    var useGradient: Bool = true
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var progressColor: Color {
        if !useGradient {
            return colorScheme == .dark ? .white : .black
        }
        return .clear
    }
    
    private var progressGradient: AngularGradient {
        let isDark = colorScheme == .dark
        
        if isExceeded {
            return AngularGradient(
                gradient: Gradient(colors: isDark ? [
                    Color(hex: "5E81AC"),
                    Color(hex: "88C0D0"),
                    Color(hex: "88C0D0"),
                    Color(hex: "D8DEE9"),
                    Color(hex: "5E81AC")
                ] : [
                    Color(hex: "98FB98"),
                    Color(hex: "D1FFD5"),
                    Color(hex: "1a945e"),
                    Color(hex: "98FB98")
                ]),
                center: .center,
                startAngle: .degrees(-90),
                endAngle: .degrees(270)
            )
        } else if isCompleted {
            return AngularGradient(
                gradient: Gradient(colors: isDark ? [
                    Color(hex: "28B463"),
                    Color(hex: "3EB489"),
                    Color(hex: "3EB489"),
                    Color(hex: "D1FFD5"),
                    Color(hex: "28B463")
                ] : [
                    Color(hex: "28B463"),
                    Color(hex: "D1FFD5"),
                    Color(hex: "3EB489"),
                    Color(hex: "28B463")
                ]),
                center: .center,
                startAngle: .degrees(-90),
                endAngle: .degrees(270)
            )
        } else {
            return AngularGradient(
                gradient: Gradient(colors: isDark ? [
                    Color(hex: "ffaf7b"),
                    Color(hex: "d76d77"),
                    Color(hex: "d76d77"),
                    Color(hex: "f4e2d8"),
                    Color(hex: "ffaf7b")
                ] : [
                    Color(hex: "ffaf7b"),
                    Color(hex: "FFF5EE"),
                    Color(hex: "d76d77"),
                    Color(hex: "ffaf7b")
                ]),
                center: .center,
                startAngle: .degrees(-90),
                endAngle: .degrees(270)
            )
        }
    }
    
    var body: some View {
        ZStack {
            // background circle
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress
            if useGradient {
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(
                        progressGradient,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
            } else {
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(
                        progressColor,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
            }
            
            // Current value or Done text
            if isCompleted && !isExceeded {
                Text("🏆")
                    .font(.system(size: size * 0.38, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(hex: "28B463"))
            } else {
                Text(currentValue)
                    .font(.system(size: size * 0.18, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isExceeded ? Color(hex: "28B463") : .primary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressRing(
            progress: 1.0,
            currentValue: "100%",
            isCompleted: true,
            isExceeded: false,
            size: 180,
            lineWidth: 24,
            useGradient: true
        )
        .padding()
        
        ProgressRing(
            progress: 1.1,
            currentValue: "110%",
            isCompleted: true,
            isExceeded: true,
            size: 180,
            lineWidth: 24,
            useGradient: true
        )
        .padding()
        
        ProgressRing(
            progress: 0.98,
            currentValue: "98%",
            isCompleted: false,
            isExceeded: false,
            size: 180,
            lineWidth: 24,
            useGradient: true
        )
        .padding()
    }
}
