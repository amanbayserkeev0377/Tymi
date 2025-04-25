import SwiftUI

struct ProgressRing: View {
    let progress: Double
    let currentValue: String
    let isCompleted: Bool
    let isExceeded: Bool
    var size: CGFloat = 180
    var lineWidth: CGFloat = 22
    @Environment(\.colorScheme) var colorScheme
    
    private var ringColors: [Color] {
        if isExceeded {
            return colorScheme == .dark ? [
                Color(#colorLiteral(red: 0.4823529412, green: 0.262745098, blue: 0.5921568627, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.3725490196, blue: 0.4274509804, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.9294117647, blue: 0.737254902, alpha: 1)),
                Color(#colorLiteral(red: 0.4823529412, green: 0.262745098, blue: 0.5921568627, alpha: 1))
            ] : [
                Color(#colorLiteral(red: 0.3249471814, green: 0.1565204025, blue: 0.6371133207, alpha: 1)),
                Color(#colorLiteral(red: 0.8431372549, green: 0.4274509804, blue: 0.4666666667, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.6862745098, blue: 0.4823529412, alpha: 1)),
                Color(#colorLiteral(red: 0.3249471814, green: 0.1565204025, blue: 0.6371133207, alpha: 1))
            ]
        } else if isCompleted {
            return colorScheme == .dark ? [
                Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1)),
                Color(#colorLiteral(red: 0.1803921569, green: 0.5450980392, blue: 0.3411764706, alpha: 1)),
                Color(#colorLiteral(red: 0.8196078431, green: 1, blue: 0.8352941176, alpha: 1)),
                Color(#colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)),
                Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1))
            ] : [
                Color(#colorLiteral(red: 0.2460050897, green: 0.606021149, blue: 0.1196907728, alpha: 1)),
                Color(#colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)),
                Color(#colorLiteral(red: 0.5960784314, green: 0.9843137255, blue: 0.5960784314, alpha: 1)),
                Color(#colorLiteral(red: 0, green: 0.459711194, blue: 0.3089413643, alpha: 1)),
                Color(#colorLiteral(red: 0.2460050897, green: 0.606021149, blue: 0.1196907728, alpha: 1))
            ]
        } else {
            return colorScheme == .dark ? [
                Color(#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)),
                Color(#colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.8805306554, blue: 0.5692787766, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.6470588235, blue: 0, alpha: 1)),
                Color(#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1))
            ] : [
                Color(#colorLiteral(red: 0.8246330492, green: 0.248637448, blue: 0.2358496644, alpha: 1)),
                Color(#colorLiteral(red: 0.9803921569, green: 0.446577528, blue: 0.02857491563, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.8419879334, blue: 0.3410575817, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.7249163399, blue: 0.1219073513, alpha: 1)),
                Color(#colorLiteral(red: 0.8246330492, green: 0.248637448, blue: 0.2358496644, alpha: 1))
            ]
        }
    }
    
    private var textColor: Color {
        if isExceeded {
            return colorScheme == .dark ?
            Color(#colorLiteral(red: 1, green: 0.3806057187, blue: 0.1013509959, alpha: 1)) :
            Color(#colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1))
        } else if isCompleted {
            return colorScheme == .dark ?
            Color(#colorLiteral(red: 0.8196078431, green: 1, blue: 0.8352941176, alpha: 1)) :
            Color(#colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1))
        } else {
            return .primary
        }
    }
    
    private var rotationAngle: Double {
        if isExceeded {
            return (progress - 1.0) * 360
        }
        return 0
    }
    
    var body: some View {
        ZStack {
            // Фоновый круг
            Circle()
                .stroke(Color.secondary.opacity(0.1), lineWidth: lineWidth)
            
            // Кольцо прогресса
            Circle()
                .trim(from: 0, to: isExceeded ? 1 : progress)
                .stroke(
                    AngularGradient(
                        colors: ringColors,
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .rotationEffect(.degrees(rotationAngle))
            
            // Текст в центре
            if isCompleted && !isExceeded {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.25, weight: .bold))
                    .foregroundStyle(textColor)
            } else {
                Text(currentValue)
                    .font(.system(size: size * 0.18, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(textColor)
            }
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: 0.3), value: progress)
    }
}

#Preview("Темная тема") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 40) {
            Text("Темная тема")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 20)
            
            ProgressRing(
                progress: 1.0,
                currentValue: "20",
                isCompleted: true,
                isExceeded: false
            )
            
            ProgressRing(
                progress: 0.99,
                currentValue: "18",
                isCompleted: false,
                isExceeded: false
            )
            
            ProgressRing(
                progress: 2.0,
                currentValue: "40",
                isCompleted: true,
                isExceeded: true
            )
        }
        .padding()
        .background {
            let cornerRadius: CGFloat = 40
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        Color.white.opacity(0.1),
                        lineWidth: 1.5
                    )
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("Светлая тема") {
    ZStack {
        Color.white.ignoresSafeArea()
        
        VStack(spacing: 40) {
            Text("Светлая тема")
                .font(.headline)
                .foregroundColor(.black)
                .padding(.top, 20)
            
            ProgressRing(
                progress: 1.0,
                currentValue: "20",
                isCompleted: true,
                isExceeded: false
            )
            
            ProgressRing(
                progress: 0.99,
                currentValue: "18",
                isCompleted: false,
                isExceeded: false
            )
            
            ProgressRing(
                progress: 2.0,
                currentValue: "40",
                isCompleted: true,
                isExceeded: true
            )
        }
        .padding()
        .background {
            let cornerRadius: CGFloat = 40
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.5))
                
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        Color.black.opacity(0.15),
                        lineWidth: 1.5
                    )
            }
        }
        .padding()
    }
    .preferredColorScheme(.light)
}
