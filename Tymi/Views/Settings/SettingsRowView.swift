import SwiftUI

struct SettingsRowView: View {
    let icon: String
    let title: String
    let hasChevron: Bool
    var toggleBinding: Binding<Bool>?
    var action: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        icon: String,
        title: String,
        hasChevron: Bool = false,
        toggleBinding: Binding<Bool>? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.hasChevron = hasChevron
        self.toggleBinding = toggleBinding
        self.action = action
    }
    
    var body: some View {
        Button(action: { action?() }) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 28, height: 28)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                
                Text(title)
                    .font(.body)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                
                Spacer()
                
                if let binding = toggleBinding {
                    Toggle("", isOn: binding)
                        .labelsHidden()
                        .tint(.black)
                } else if hasChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.gray)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
} 