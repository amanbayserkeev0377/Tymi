import SwiftUI

struct NameFieldSection: View {
    @Binding var title: String
    @FocusState.Binding var isFocused: Bool
    
    var body: some View {
        Section {
            HStack {
                Image(systemName: "pencil")
                    .foregroundStyle(.primary)
                
                TextField("Habit Name", text: $title)
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
