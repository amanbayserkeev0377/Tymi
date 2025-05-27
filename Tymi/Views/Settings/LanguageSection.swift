import SwiftUI

struct LanguageSection: View {
    private var currentLanguage: String {
        let locale = Locale.current
        guard let languageCode = locale.language.languageCode?.identifier else {
            return "Unknown"
        }
        
        let languageName = locale.localizedString(forLanguageCode: languageCode) ?? languageCode
        
        return languageName.prefix(1).uppercased() + languageName.dropFirst()
    }
    
    var body: some View {
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack {
                Label(
                    title: { Text("language".localized) },
                    icon: {
                        Image(systemName: "translate")
                            .withIOSSettingsIcon(lightColors: [
                                Color(#colorLiteral(red: 0.2666666667, green: 0.6274509804, blue: 1, alpha: 1)),
                                Color(#colorLiteral(red: 0.0, green: 0.2784313725, blue: 0.6745098039, alpha: 1))
                            ],
                            fontSize: 11
                            )
                    }
                )
                
                Spacer()
                
                Text(currentLanguage)
                    .foregroundStyle(.secondary)
                
                Image(systemName: "arrow.up.right")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundStyle(.tertiary)
            }
        }
        .tint(.primary)
    }
}
