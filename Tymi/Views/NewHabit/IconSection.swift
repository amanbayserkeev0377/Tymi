import SwiftUI

struct IconSection: View {
    @Binding var selectedIcon: String?
    @Binding var selectedColor: HabitIconColor
    @ObservedObject private var colorManager = AppColorManager.shared
    
    private let defaultIcon = "checkmark"
    
    // Добавь эту функцию
    private func isCustomIcon(_ iconName: String) -> Bool {
        return iconName.hasPrefix("icon_")
    }
    
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
                    let iconName = selectedIcon ?? defaultIcon
                    
                    // Проверяем тип иконки
                    if isCustomIcon(iconName) {
                        Image(iconName) // Кастомная из Assets
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundStyle(selectedColor.color)
                    } else {
                        Image(systemName: iconName) // SF Symbol
                            .foregroundStyle(selectedIcon == nil ? colorManager.selectedColor.color : selectedColor.color)
                    }
                }
            }
        }
    }
}
