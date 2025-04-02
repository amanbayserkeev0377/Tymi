import SwiftUI

struct ProgressCircleView: View {
    let progress: Double
    let goal: Double
    let type: HabitType
    let isCompleted: Bool
    let currentValue: Double
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var circleSize: CGFloat {
        min(UIScreen.main.bounds.width * 0.65, 260)
    }
    
    private var progressPercentage: Double {
        min(progress / goal, 1.0)
    }
    
    private var gradientColors: [Color] {
        if isCompleted {
            return [.green, .mint]
        }
        return type == .count ? [.blue, .purple] : [.indigo, .pink]
    }
    
    private var trackColor: Color {
        colorScheme == .light 
            ? Color.black.opacity(0.08)
            : Color.white.opacity(0.12)
    }
    
    private var shadowColor: Color {
        colorScheme == .light 
            ? .black.opacity(0.2)
            : .black.opacity(0.4)
    }
    
    private var glowColor: Color {
        colorScheme == .light
            ? .white.opacity(0.5)
            : .white.opacity(0.3)
    }
    
    private var ringWidth: CGFloat { 32 }
    
    var body: some View {
        ZStack {
            // Glow Aura
            Circle()
                .trim(from: 0, to: progressPercentage)
                .fill(
                    AngularGradient(
                        colors: gradientColors,
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    )
                )
                .blur(radius: 30)
                .opacity(0.3)
                .rotationEffect(.degrees(-90))
            
            // Background Track
            Circle()
                .fill(trackColor)
                .mask {
                    ZStack {
                        Circle()
                        Circle()
                            .inset(by: ringWidth)
                            .fill(Color.black)
                            .blendMode(.destinationOut)
                    }
                }
            
            // Progress Circle
            Circle()
                .fill(
                    AngularGradient(
                        colors: gradientColors + [gradientColors[0]],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    )
                )
                .mask {
                    Path { path in
                        path.addArc(
                            center: CGPoint(x: circleSize/2, y: circleSize/2),
                            radius: (circleSize - ringWidth) / 2,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(-90 + 360 * progressPercentage),
                            clockwise: false
                        )
                        path.addArc(
                            center: CGPoint(x: circleSize/2, y: circleSize/2),
                            radius: circleSize/2,
                            startAngle: .degrees(-90 + 360 * progressPercentage),
                            endAngle: .degrees(-90),
                            clockwise: true
                        )
                        path.closeSubpath()
                    }
                }
                .animation(.spring(response: 0.6), value: progressPercentage)
            
            // Outer glow
            Circle()
                .trim(from: 0, to: progressPercentage)
                .stroke(
                    glowColor,
                    style: StrokeStyle(
                        lineWidth: 1,
                        lineCap: .round
                    )
                )
                .blur(radius: 1)
                .rotationEffect(.degrees(-90))
            
            // Center Content
            VStack(spacing: 8) {
                if isCompleted {
                    Text("Done")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(
                            color: shadowColor,
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                } else {
                    Text(valueText)
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                        .shadow(
                            color: shadowColor,
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                    
                    if type == .time {
                        Text("of \(goalText)")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .animation(.spring(response: 0.3), value: isCompleted)
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
            if hours > 0 {
                return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%02d:%02d", minutes, seconds)
            }
        }
    }
    
    private var goalText: String {
        switch type {
        case .count:
            return "\(Int(goal))"
        case .time:
            let hours = Int(goal) / 3600
            let minutes = Int(goal) / 60 % 60
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        }
    }
} 
