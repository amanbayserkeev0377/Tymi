import SwiftUI

struct ProgressCircle: View {
    let progress: Double
    let isCompleted: Bool
    let size: CGFloat = 40
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    isCompleted ? Color.green : Color.black,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
            
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundStyle(.green)
            }
        }
    }
}
