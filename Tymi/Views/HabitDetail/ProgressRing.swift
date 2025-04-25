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
                Color(#colorLiteral(red: 0.3273690343, green: 0.170719862, blue: 0.3585013449, alpha: 1)),
                Color(#colorLiteral(red: 0.7270964384, green: 0.4991361499, blue: 0.4899051189, alpha: 1)),
                Color(#colorLiteral(red: 0.9588896632, green: 0.8931894898, blue: 0.8644337654, alpha: 1)),
                Color(#colorLiteral(red: 0.5469533205, green: 0.3803724051, blue: 0.5527326465, alpha: 1)),
                Color(#colorLiteral(red: 0.3273690343, green: 0.170719862, blue: 0.3585013449, alpha: 1))
            ] : [
                Color(#colorLiteral(red: 0.7340632677, green: 0.4394526482, blue: 0.7660113573, alpha: 1)),
                Color(#colorLiteral(red: 0.9803921569, green: 0.6745098039, blue: 0.6588235294, alpha: 1)),
                Color(#colorLiteral(red: 0.9831311107, green: 0.8466018438, blue: 0.7147132754, alpha: 1)),
                Color(#colorLiteral(red: 0.8413342834, green: 0.7343104482, blue: 0.9628780484, alpha: 1)),
                Color(#colorLiteral(red: 0.7340632677, green: 0.4394526482, blue: 0.7660113573, alpha: 1))
            ]
        } else if isCompleted {
            return colorScheme == .dark ? [
                Color(#colorLiteral(red: 0, green: 0.247739166, blue: 0.1666022539, alpha: 1)),
                Color(#colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)),
                Color(#colorLiteral(red: 0.8196078431, green: 1, blue: 0.8352941176, alpha: 1)),
                Color(#colorLiteral(red: 0, green: 0.459711194, blue: 0.3089413643, alpha: 1)),
                Color(#colorLiteral(red: 0, green: 0.247739166, blue: 0.1666022539, alpha: 1))
            ] : [
                Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1)),
                Color(#colorLiteral(red: 0.1803921569, green: 0.5450980392, blue: 0.3411764706, alpha: 1)),
                Color(#colorLiteral(red: 0.5960784314, green: 0.9843137255, blue: 0.5960784314, alpha: 1)),
                Color(#colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)),
                Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1))
            ]
        } else {
            return colorScheme == .dark ? [
                Color(#colorLiteral(red: 0.568877697, green: 0.1204769239, blue: 0.06241762638, alpha: 1)),
                Color(#colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.8805306554, blue: 0.5692787766, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.6470588235, blue: 0, alpha: 1)),
                Color(#colorLiteral(red: 0.568877697, green: 0.1204769239, blue: 0.06241762638, alpha: 1))
            ] : [
                Color(#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)),
                Color(#colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)),
                Color(#colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)),
                Color(#colorLiteral(red: 0.9891677499, green: 0.4991324544, blue: 0, alpha: 0.7806032699)),
                Color(#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1))
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
