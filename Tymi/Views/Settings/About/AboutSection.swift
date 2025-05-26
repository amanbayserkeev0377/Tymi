import SwiftUI

struct ExternalLinkModifier: ViewModifier {
    var trailingText: String? = nil
    
    func body(content: Content) -> some View {
        HStack {
            content
            Spacer()
            
            if let text = trailingText {
                Text(text)
                    .foregroundStyle(.secondary)
            }
            
            Image(systemName: "arrow.up.right")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(.tertiary)
        }
    }
}

extension View {
    func withExternalLinkIcon(trailingText: String? = nil) -> some View {
        self.modifier(ExternalLinkModifier(trailingText: trailingText))
    }
}

struct AboutSection: View {
    var body: some View {
        Section {
            // How to Use
            NavigationLink(destination: HowToUseView()) {
                Label("how_to_use".localized, systemImage: "questionmark.app")
            }
            
            // Rate App
            Button {
                if let url = URL(string: "https://apps.apple.com/app/idXXXXXXXXXX") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("rate_app".localized, systemImage: "star")
                    .withExternalLinkIcon()
            }
            .tint(.primary)
            
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
                    .withExternalLinkIcon()
            }
            .tint(.primary)
            
            // Contact Developer
            Button {
                if let url = URL(string: "https://t.me/amanbayserkeev0377") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("contact_developer".localized, systemImage: "ellipsis.message")
                    .withExternalLinkIcon()
            }
            .tint(.primary)
            
            // Report a Bug
            Button {
                if let url = URL(string: "mailto:amanbayserkeev0377@gmail.com?subject=Bug%20Report") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("report_bug".localized, systemImage: "ladybug")
                    .withExternalLinkIcon()
            }
            .tint(.primary)
        }
        
        // MARK: - Legal
        
        // Terms of Service
        Section {
            NavigationLink(destination: TermsOfServiceView()) {
                Label("terms_of_service".localized, systemImage: "text.document")
            }
            
            // Privacy Policy
            NavigationLink(destination: PrivacyPolicyView()) {
                Label("privacy_policy".localized, systemImage: "lock")
            }
        }
    }
}
