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
        return [.purple, .pink, .orange]
    }
    
    private var trackColor: Color {
        colorScheme == .light 
            ? Color.black.opacity(0.06)
            : Color.white.opacity(0.1)
    }
    
    private var shadowColor: Color {
        colorScheme == .light 
            ? .black.opacity(0.2)
            : .black.opacity(0.4)
    }
    
    private var glowColor: Color {
        colorScheme == .light
            ? .white.opacity(0.6)
            : .white.opacity(0.3)
    }
    
    private var ringWidth: CGFloat { 40 }
    
    var body: some View {
        ZStack {
            // Glass background
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle()
                        .fill(
                            .linearGradient(
                                colors: [
                                    .white.opacity(colorScheme == .light ? 0.5 : 0.2),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    Circle()
                        .stroke(
                            .linearGradient(
                                colors: [
                                    .white.opacity(0.5),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
            
            // Background Track
            Circle()
                .stroke(
                    trackColor,
                    style: StrokeStyle(
                        lineWidth: ringWidth,
                        lineCap: .round
                    )
                )
                .overlay(
                    Circle()
                        .stroke(
                            .linearGradient(
                                colors: [
                                    .white.opacity(0.3),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
            
            // Glow Effect
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
                        lineWidth: ringWidth + 20,
                        lineCap: .round
                    )
                )
                .blur(radius: 20)
                .opacity(0.3)
                .rotationEffect(.degrees(-90))
            
            // Progress Ring
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
                .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
                .rotationEffect(.degrees(-90))
                .overlay(
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
                )
                .animation(.easeInOut(duration: 0.3), value: progressPercentage)
            
            // Center Content
            VStack(spacing: 8) {
                if isCompleted {
                    Text("Done")
                        .font(.system(size: 68, weight: .bold))
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
                        .font(.system(size: 68, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .contentTransition(.numericText())
                        .shadow(
                            color: shadowColor,
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                    
                    if type == .time {
                        Text("of \(goalText)")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isCompleted)
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
