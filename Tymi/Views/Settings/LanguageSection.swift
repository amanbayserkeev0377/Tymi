import SwiftUI

struct LanguageSection: View {
    var body: some View {
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            Label("language".localized, systemImage: "translate")
                .withExternalLinkIcon()
        }
    }
}
