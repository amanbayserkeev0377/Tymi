import SwiftUI

struct NameFieldSection: View {
    @Binding var title: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Section {
            HStack {
                Image(systemName: "pencil")
                    .foregroundStyle(.primary)
                
                TextField("Habit Name", text: $title)
                    .autocorrectionDisabled()
                    .focused($isFocused)
            }
            .frame(height: 44)
        }
        .onAppear {
            isFocused = true
        }
    }
}

#Preview {
    @Previewable @State var title = ""
    
    return Form {
        NameFieldSection(title: $title)
    }
}
