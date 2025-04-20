import SwiftUI

struct ProgressRing: View {
    let progress: Double
    let currentValue: String
    
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
                .stroke(Color.secondary.opacity(0.2), lineWidth: 12)
                .frame(width: 180, height: 180)
            
            // Progress Circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
            
            // Current value text
            Text(currentValue)
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    VStack {
        ProgressRing(progress: 0.7, currentValue: "7/10")
        ProgressRing(progress: 0.3, currentValue: "00:30:00")
    }
} 
