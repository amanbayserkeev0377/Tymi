import SwiftUI

struct ProgressRing: View {
    let progress: Double
    let currentValue: String
    let isCompleted: Bool
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
        if isCompleted {
            return AngularGradient(
                gradient: Gradient(colors: [
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
                gradient: Gradient(colors: [
                    Color(hex: "ffaf7b"),
                    Color(hex: "b06ab3"),
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
                    .trim(from: 0, to: progress)
                    .stroke(
                        progressGradient,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
            } else {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        progressColor,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
            }
            
            // Current value or Done text
            if isCompleted {
                Text("Done🎉")
                    .font(.system(size: size * 0.18, weight: .bold))
                    .multilineTextAlignment(.center)
            } else {
                Text(currentValue)
                    .font(.system(size: size * 0.18, weight: .bold))
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressRing(
            progress: 0.99,
            currentValue: "100%",
            isCompleted: true,
            size: 180,
            lineWidth: 24,
            useGradient: true
        )
        .padding()
        
        ProgressRing(
            progress: 0.9,
            currentValue: "Sada loh",
            isCompleted: false,
            size: 180,
            lineWidth: 24,
            useGradient: true
        )
        .padding()
    }
}
