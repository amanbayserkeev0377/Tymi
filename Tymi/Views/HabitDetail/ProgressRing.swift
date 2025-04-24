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
                Color(#colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)),
                Color(#colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.7019607843, blue: 0.2, alpha: 1)),
                Color(#colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1))
            ] : [
                Color(#colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)),
                Color(#colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.7019607843, blue: 0.2, alpha: 1)),
                Color(#colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1))
            ]
        } else if isCompleted {
            return colorScheme == .dark ? [
                Color(#colorLiteral(red: 0.007843137255, green: 0.1882352941, blue: 0.1254901961, alpha: 1)),
                Color(#colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)),
                Color(#colorLiteral(red: 0.8196078431, green: 1, blue: 0.8352941176, alpha: 1)),
                Color(#colorLiteral(red: 0, green: 0.459711194, blue: 0.3089413643, alpha: 1)),
                Color(#colorLiteral(red: 0.007843137255, green: 0.1882352941, blue: 0.1254901961, alpha: 1))
            ] : [
                Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1)),
                Color(#colorLiteral(red: 0.1803921569, green: 0.5450980392, blue: 0.3411764706, alpha: 1)),
                Color(#colorLiteral(red: 0.7885711789, green: 0.9630113244, blue: 0.8068896532, alpha: 1)),
                Color(#colorLiteral(red: 0.5960784314, green: 0.9843137255, blue: 0.5960784314, alpha: 1)),
                Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1))
            ]
        } else {
            return colorScheme == .dark ? [
                Color(#colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)),
                Color(#colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.7019607843, blue: 0.2, alpha: 1)),
                Color(#colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1))
            ] : [
                Color(#colorLiteral(red: 0.9803921569, green: 0.6745098039, blue: 0.6588235294, alpha: 1)),
                Color(#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)),
                Color(#colorLiteral(red: 0.9098039216, green: 0.9176470588, blue: 0.9058823529, alpha: 1)),
                Color(#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)),
                Color(#colorLiteral(red: 0.9803921569, green: 0.6745098039, blue: 0.6588235294, alpha: 1))
            ]
        }
    }
    
    private var textColor: Color {
        if isExceeded {
            return colorScheme == .dark ?
                Color(#colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)) :
                Color(#colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1))
        } else if isCompleted {
            return colorScheme == .dark ? 
                Color(#colorLiteral(red: 0.8196078431, green: 1, blue: 0.8352941176, alpha: 1)) :
                Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1))
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
                .stroke(Color.secondary.opacity(0.2), lineWidth: lineWidth)
            
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

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 40) {
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
                progress: 1.2,
                currentValue: "40",
                isCompleted: true,
                isExceeded: true
            )
        }
    }
}
