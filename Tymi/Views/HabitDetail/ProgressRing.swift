import SwiftUI

struct ProgressRing: View {
    let progress: Double
    let currentValue: String
    let isCompleted: Bool
    let isExceeded: Bool
    var size: CGFloat = 180
    var lineWidth: CGFloat = 24
    
    // Цвета для градиента
    private var ringColors: [Color] {
        if isCompleted || isExceeded {
            return [
                Color(hex: "28B463"), // Темно-зеленый
                Color(hex: "D1FFD5"), // Светло-зеленый
                Color(hex: "28B463")  // Снова темно-зеленый для конца
            ]
        } else {
            return [
                Color(hex: "ffaf7b"), // Оранжевый
                Color(hex: "FFF5EE"), // Светлый
                Color(hex: "ffaf7b")  // Снова оранжевый для конца
            ]
        }
    }
    
    var body: some View {
        ZStack {
            // Фоновый круг
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            ZStack {
                if progress < 0.98 {
                    // Обычный прогресс
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: ringColors),
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            ),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(-90))
                    
                    // Фиксируем начало градиента
                    Circle()
                        .frame(width: lineWidth, height: lineWidth)
                        .foregroundColor(ringColors[0])
                        .offset(y: -size/2)
                        
                } else {
                    // Полное заполнение или перевыполнение
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: ringColors),
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            ),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees((360 * progress) - 90))
                    
                    // Кончик для перевыполнения
                    Circle()
                        .frame(width: lineWidth, height: lineWidth)
                        .foregroundColor(ringColors[2])
                        .offset(y: -size/2)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: lineWidth/4, y: 0)
                        .rotationEffect(.degrees(360 * progress))
                }
            }
            .animation(.easeInOut(duration: 0.5), value: progress)
            
            if isCompleted && !isExceeded {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.25, weight: .bold))
                    .foregroundStyle(ringColors[0])
            } else {
                Text(currentValue)
                    .font(.system(size: size * 0.18, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isExceeded ? ringColors[0] : .primary)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 40) {
            ProgressRing(
                progress: 0.75,
                currentValue: "15",
                isCompleted: false,
                isExceeded: false,
                size: 180,
                lineWidth: 24
            )
            
            ProgressRing(
                progress: 1.0,
                currentValue: "20",
                isCompleted: true,
                isExceeded: false,
                size: 180,
                lineWidth: 24
            )
            
            ProgressRing(
                progress: 0.99,
                currentValue: "25",
                isCompleted: false,
                isExceeded: false,
                size: 180,
                lineWidth: 24
            )
            
            ProgressRing(
                progress: 2.75,
                currentValue: "55",
                isCompleted: true,
                isExceeded: true,
                size: 180,
                lineWidth: 24
            )
        }
    }
}
