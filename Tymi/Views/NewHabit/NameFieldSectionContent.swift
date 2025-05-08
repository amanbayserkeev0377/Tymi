import SwiftUI

struct NameFieldSectionContent: View {
    @Binding var title: String
    @FocusState.Binding var isFocused: Bool
    
    var body: some View {
        Section {
            TextField("habit_name".localized, text: $title)
                .autocorrectionDisabled()
                .focused($isFocused)
                .tint(.primary)
                .frame(height: 37)
        }
    }
}
