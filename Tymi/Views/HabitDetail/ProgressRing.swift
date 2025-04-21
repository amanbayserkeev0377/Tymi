import SwiftUI

struct ProgressRing: View {
    let progress: Double
    let currentValue: String
    var size: CGFloat = 180
    var lineWidth: CGFloat = 12
    var useGradient: Bool = true
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var progressColor: Color {
        if !useGradient {
            return colorScheme == .dark ? .white : .black
        }
        return .clear
    }
    
    private var progressGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [.blue, .purple, .blue]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )
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
            
            // Current value
            Text(currentValue)
                .font(.system(size: size * 0.18, weight: .bold))
                .multilineTextAlignment(.center)
        }
    }
}
