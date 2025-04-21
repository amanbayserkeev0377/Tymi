import SwiftUI

struct AddFloatingButton: View {
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        colorScheme == .dark
                        ? Color.white.opacity(0.3)
                        : Color.black.opacity(0.3)
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(
                                colorScheme == .dark
                                ? Color.white.opacity(0.2)
                                : Color.black.opacity(0.3),
                                lineWidth: 0.5
                            )
                    )
                
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        colorScheme == .dark
                        ? Color.white.opacity(0.6)
                        : Color.white.opacity(0.8)
                    )
            }
            .frame(width: 48, height: 48)
        }
        .padding(16)
        .shadow(
            color: colorScheme == .dark
            ? Color.white.opacity(0.4)
            : Color.black,
            radius: 10, x: 0, y: 4
        )
    }
}

struct AddFloatingButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AddFloatingButton(action: {})
                .preferredColorScheme(.light)
                .previewLayout(.sizeThatFits)
                .padding()
                .background(Color(.systemBackground))
                .previewDisplayName("Light Theme")
            
            AddFloatingButton(action: {})
                .preferredColorScheme(.dark)
                .previewLayout(.sizeThatFits)
                .padding()
                .background(Color(.systemBackground))
                .previewDisplayName("Dark Theme")
        }
    }
}
