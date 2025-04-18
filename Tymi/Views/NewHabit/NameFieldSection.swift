import SwiftUI

struct NameFieldSection: View {
    @Binding var title: String
    
    var body: some View {
        Section(header: Text("Name")) {
            TextField("Reading", text: $title)
                .autocorrectionDisabled()
        }
    }
}

#Preview {
    @Previewable @State var title = ""
    
    return Form {
        NameFieldSection(title: $title)
    }
}
