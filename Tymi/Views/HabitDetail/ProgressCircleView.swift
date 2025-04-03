import SwiftUI

struct ProgressCircleView: View {
    let progress: Double
    let goal: Double
    let type: HabitType
    let isCompleted: Bool
    let currentValue: Double
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var circleSize: CGFloat {
        min(UIScreen.main.bounds.width * 0.55, 220)
    }
    
    private var progressPercentage: Double {
        min(progress / goal, 1.0)
    }
    
    private var gradientColors: [Color] {
        if isCompleted {
            return [.green, .mint]
        }
        if colorScheme == .dark {
            return [
                Color(hex: "ba5370"), // 4
                Color(hex: "4e4376"), // 1
                Color(hex: "d76d77"), // 2
                Color(hex: "ffaf7b") // 3
            ]

        } else {
            return [
                Color(red: 180/255, green: 215/255, blue: 255/255),
                Color(red: 255/255, green: 190/255, blue: 255/255),
                Color(red: 255/255, green: 143/255, blue: 107/255),
                Color(red: 255/255, green: 150/255, blue: 170/255)
            ]
        }
    }
    
    
    private var trackColor: Color {
        colorScheme == .light ? .black.opacity(0.06) : .white.opacity(0.1)
    }
    
    private var textColor: Color {
        colorScheme == .light ? .black : .white
    }
    
    private var ringWidth: CGFloat { 32 }
    
    var body: some View {
        ZStack {
            // Track ring
            Circle()
                .stroke(
                    trackColor,
                    style: StrokeStyle(
                        lineWidth: ringWidth,
                        lineCap: .round
                    )
                )
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progressPercentage)
                .stroke(
                    AngularGradient(
                        colors: gradientColors + [gradientColors[0]],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(
                        lineWidth: ringWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progressPercentage)
            
            // Center value
            VStack(spacing: 8) {
                Text(isCompleted ? "Done" : valueText)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(textColor)
                    .contentTransition(.numericText())
                
                if type == .time && !isCompleted {
                    Text("of \(goalText)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: circleSize, height: circleSize)
    }
    
    private var valueText: String {
        switch type {
        case .count:
            return "\(Int(currentValue))"
        case .time:
            let hours = Int(currentValue) / 3600
            let minutes = Int(currentValue) / 60 % 60
            let seconds = Int(currentValue) % 60
            return hours > 0
            ? String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private var goalText: String {
        switch type {
        case .count:
            return "\(Int(goal))"
        case .time:
            let hours = Int(goal) / 3600
            let minutes = Int(goal) / 60 % 60
            return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
        }
    }
}

#Preview {
    ZStack {
        Color.white
            .opacity(0.01)
            .background(.ultraThinMaterial)
            .ignoresSafeArea()
        
        ProgressCircleView(
            progress: 116,
            goal: 120,
            type: .count,
            isCompleted: false,
            currentValue: 119
        )
        .padding(40)
    }
    .preferredColorScheme(.dark)
}
