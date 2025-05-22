import SwiftUI

struct IconSection: View {
    @Binding var selectedIcon: String?
    @Binding var selectedColor: HabitIconColor
    
    private let defaultIcon = "checkmark"
    
    var body: some View {
        NavigationLink {
            IconPickerView(
                selectedIcon: $selectedIcon,
                selectedColor: $selectedColor
            )
        } label: {
            HStack {
                Label {
                    Text("icon".localized)
                } icon: {
                    Image(systemName: selectedIcon ?? defaultIcon)
                        .foregroundStyle(selectedIcon == nil ? .accentColor : selectedColor.color)
                }
            }
        }
    }
}
