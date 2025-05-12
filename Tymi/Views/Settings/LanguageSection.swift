import SwiftUI

struct LanguageSection: View {
    var body: some View {
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            Label(
                title: { Text("language".localized) },
                icon: { Image(systemName: "translate") }
            )
        }
    }
}
