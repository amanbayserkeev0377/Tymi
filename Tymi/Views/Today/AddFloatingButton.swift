import SwiftUI

struct AddFloatingButton: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        colorScheme == .dark
                        ? Color.white.opacity(0.9)
                        : Color.black.opacity(0.9)
                    )
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle()
                            .stroke(
                                colorScheme == .dark
                                ? .white
                                : Color.black.opacity(0.1),
                                lineWidth: 0.5
                            )
                        )
                    
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        colorScheme == .dark ? .black : .white
                    )
            }
            
            .frame(width: 52, height: 52)
        }
    }
}

#Preview("Light Mode") {
    AddFloatingButton(action: {})
        .preferredColorScheme(.light)
        .padding()
}

#Preview("Dark Mode") {
    AddFloatingButton(action: {})
        .preferredColorScheme(.dark)
        .padding()
}


