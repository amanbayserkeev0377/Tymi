import SwiftUI

struct AboutSection: View {
    var body: some View {
        Section(header: Text("about".localized)) {
            // Оценить приложение
            Button {
                if let url = URL(string: "https://apps.apple.com/app/idXXXXXXXXXX") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("rate_app".localized, systemImage: "star")
            }
            
            // Поделиться приложением
            Button {
                let activityVC = UIActivityViewController(
                    activityItems: ["Check out Tymi app!"],
                    applicationActivities: nil
                )
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    rootVC.present(activityVC, animated: true)
                }
            } label: {
                Label("share_app".localized, systemImage: "square.and.arrow.up")
            }
            
            // Связаться с разработчиком
            Button {
                if let url = URL(string: "https://t.me/amanbayserkeev0377") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("contact_developer".localized, systemImage: "ellipsis.message")
            }
            
            // Сообщить о проблеме
            Button {
                if let url = URL(string: "mailto:support@tymi.app?subject=Bug%20Report") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("report_bug".localized, systemImage: "ladybug")
            }
        }
        
        Section(header: Text("legal".localized)) {
            // Условия использования
            Button {
                if let url = URL(string: "https://tymi.app/terms") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("terms_of_service".localized, systemImage: "text.document")
            }
            
            // Политика конфиденциальности
            Button {
                if let url = URL(string: "https://tymi.app/privacy") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("privacy_policy".localized, systemImage: "lock")
            }
        }
        
        Section {
            HStack {
                Text("app_version".localized)
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
