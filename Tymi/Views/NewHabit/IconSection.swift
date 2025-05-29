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
            HStack(spacing: 12) {
                Image(systemName: selectedIcon ?? "checkmark")
                    .foregroundStyle(selectedIcon == "checkmark" ? AppColorManager.shared.selectedColor.color : selectedColor.color)
                    .font(.system(size: 22))
                    .frame(width: 30)
                    .clipped()
                Text("icon".localized)
                
                Spacer()
            }
        }
    }
}
