import SwiftUI

/// A styled close button "X" that matches Apple's default UI style
struct XmarkView: View {
    var action: () -> Void
    
    // MARK: - Properties
    
    /// The size of the button
    var size: CGFloat = 30
    
    /// Optional tint color for the X icon (default is systemGray)
    var iconColor: Color = Color(.systemGray)
    
    /// Background style settings
    var backgroundColor: Color = Color(.systemGray5)
    var cornerRadius: CGFloat = 15
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(backgroundColor)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain) // Removes default button styling
    }
}

// MARK: - Convenience View Extensions

extension View {
    /// Adds a standard iOS-style dismiss X button to the top trailing corner of the view
    func withDismissButton(onDismiss: @escaping () -> Void) -> some View {
        self.overlay(
            XmarkView(action: onDismiss)
                .padding(.top, 8)
                .padding(.trailing, 8),
            alignment: .topTrailing
        )
    }
}
