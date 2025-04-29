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
                    .settingsIcon()
                
                Text("Language")
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .padding(.trailing)
            }
        }
        .tint(.primary)
        .frame(height: 37)
    }
}

#Preview {
    LanguageSection()
        .padding()
        .previewLayout(.sizeThatFits)
} 
