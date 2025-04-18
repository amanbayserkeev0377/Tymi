import SwiftUI

struct ProgressCircle: View {
    let progress: Double
    let isCompleted: Bool
    var size: CGFloat = 40
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    isCompleted ? Color.black : Color.black,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
            
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundStyle(.black)
            }
        }
        .environment(\.colorScheme, .light) // Force light mode colors
        .preferredColorScheme(nil) // Allow system to apply dark mode automatically
    }
}

// Dark mode compatible version that automatically adapts
struct AdaptiveProgressCircle: View {
    let progress: Double
    let isCompleted: Bool
    var size: CGFloat = 40
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var progressColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var backgroundColorOpacity: Double {
        colorScheme == .dark ? 0.3 : 0.2
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(backgroundColorOpacity), lineWidth: 4)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
            
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundStyle(progressColor)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            Text("Light Mode:")
            
            ProgressCircle(progress: 0.3, isCompleted: false)
            ProgressCircle(progress: 1.0, isCompleted: true)
        }
        .preferredColorScheme(.light)
        
        HStack(spacing: 20) {
            Text("Dark Mode:")
            
            AdaptiveProgressCircle(progress: 0.3, isCompleted: false)
            AdaptiveProgressCircle(progress: 1.0, isCompleted: true)
        }
        .preferredColorScheme(.dark)
    }
    .padding()
}
