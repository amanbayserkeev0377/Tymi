import SwiftUI

struct IconSection: View {
    @Binding var selectedIcon: String?
    
    private var displayIcon: some View {
        if let iconName = selectedIcon {
            return Image(systemName: iconName)
                .foregroundStyle(.primary)
        } else {
            return Image(systemName: "plus.circle")
                .foregroundStyle(.secondary)
        }
    }
    
    var body: some View {
        NavigationLink(destination: IconPickerView(selectedIcon: $selectedIcon)) {
            HStack {
                Label {
                    Text("icon".localized)
                } icon: {
                    displayIcon
                        .font(.body)
                        .frame(width: 25)
                }
                
                Spacer()
                
                if selectedIcon != nil {
                    displayIcon
                        .font(.title2)
                }
            }
        }
    }
}
