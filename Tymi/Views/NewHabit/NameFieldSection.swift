import SwiftUI

struct NameFieldSection: View {
    @Binding var title: String
    @FocusState.Binding var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "pencil")
                .foregroundStyle(AppColorManager.shared.selectedColor.color)
                .font(.system(size: 22))
                .frame(width: 30)
                .clipped()
            TextField("habit_name".localized, text: $title)
                .autocorrectionDisabled()
                .focused($isFocused)
        }
    }
}
