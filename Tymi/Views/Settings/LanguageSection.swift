import SwiftUI

struct LanguageSection: View {
    var body: some View {
        Button(action: {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack {
                Image(systemName: "translate")
                    .foregroundStyle(.primary)
                    .frame(width: 24, height: 24)
                
                Text("language".localized)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.primary)
    }
}

struct LanguageSection_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            LanguageSection()
                .padding()
                .previewLayout(.sizeThatFits)
                .environment(\.locale, .init(identifier: "en"))
                .previewDisplayName("English")
            
            LanguageSection()
                .padding()
                .previewLayout(.sizeThatFits)
                .environment(\.locale, .init(identifier: "ru"))
                .previewDisplayName("Russian")
        }
    }
}
