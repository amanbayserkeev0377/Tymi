import SwiftUI

struct AboutSection: View {
    var body: some View {
        Section(header: Text("about".localized)) {
            // Rate App
            Button {
                if let url = URL(string: "https://apps.apple.com/app/idXXXXXXXXXX") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("rate_app".localized, systemImage: "star")
            }
            
            // Share App
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
            
            // Contact Developer
            Button {
                if let url = URL(string: "https://t.me/amanbayserkeev0377") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("contact_developer".localized, systemImage: "ellipsis.message")
            }
            
            // Report a Bug
            Button {
                if let url = URL(string: "mailto:amanbayserkeev0377@gmail.com?subject=Bug%20Report") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("report_bug".localized, systemImage: "ladybug")
            }
            
            // How to Use
            NavigationLink(destination: HowToUseView()) {
                Label("how_to_use".localized, systemImage: "questionmark.app")
            }
        }
        
        // MARK: - Legal
        
        // Terms of Service
        Section(header: Text("legal".localized)) {
            NavigationLink(destination: TermsOfServiceView()) {
                Label("terms_of_service".localized, systemImage: "text.document")
            }
            
            // Privacy Policy
            NavigationLink(destination: PrivacyPolicyView()) {
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
