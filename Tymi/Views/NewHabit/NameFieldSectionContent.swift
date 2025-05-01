import SwiftUI

struct NameFieldSectionContent: View {
    @Binding var title: String
    @FocusState.Binding var isFocused: Bool
    
    var body: some View {
        Section {
            HStack {
                Image(systemName: "pencil")
                    .foregroundStyle(.primary)
                    .frame(width: 24, height: 24)
                
                TextField("habit_name".localized, text: $title)
                    .autocorrectionDisabled()
                    .focused($isFocused)
                    .tint(.primary)
            }
            .frame(height: 37)
        }
        .onAppear {
            isFocused = true
        }
    }
}
