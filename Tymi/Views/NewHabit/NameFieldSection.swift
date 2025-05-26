import SwiftUI

struct NameFieldSection: View {
    @Binding var title: String
    @FocusState.Binding var isFocused: Bool
    
    var body: some View {
        HStack {
            Label {
                TextField("habit_name".localized, text: $title)
                    .autocorrectionDisabled()
                    .focused($isFocused)
            } icon: {
                Image(systemName: "pencil.line")
            }
        }
    }
}
