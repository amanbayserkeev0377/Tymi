import SwiftUI

struct NameFieldSection: View {
    @Binding var title: String
    @FocusState.Binding var isFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "pencil")
                .font(.body)
                .foregroundStyle(.primary)
                .symbolEffect(.pulse, options: .repeat(1), value: title)
                .accessibilityHidden(true)
            
            TextField("habit_name".localized, text: $title)
                .autocorrectionDisabled()
                .focused($isFocused)
        }
    }
}
