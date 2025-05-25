import SwiftUI

struct IconSection: View {
    @Binding var selectedIcon: String?
    @Binding var selectedColor: HabitIconColor
    @ObservedObject private var colorManager = AppColorManager.shared
    
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
                        .foregroundStyle(selectedIcon == nil ? colorManager.selectedColor.color : selectedColor.color)
                }
            }
        }
    }
}
