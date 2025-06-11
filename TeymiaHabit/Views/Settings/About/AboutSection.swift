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

// MARK: - New Styled External Link Modifier
struct StyledExternalLinkModifier: ViewModifier {
    let lightColors: [Color]
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
    
    // New method for styled external links
    func withStyledExternalLink(lightColors: [Color], trailingText: String? = nil) -> some View {
        Label(
            title: { self },
            icon: {
                Image(systemName: "arrow.up.right") // This will be overridden
                    .withIOSSettingsIcon(lightColors: lightColors)
            }
        )
        .modifier(StyledExternalLinkModifier(lightColors: lightColors, trailingText: trailingText))
    }
}

struct AboutSection: View {
    var body: some View {
        
        // MARK: - Support & Feedback
        Section(header: Text("settings_header_support".localized)) {
            // Rate App
            Button {
                if let url = URL(string: "https://apps.apple.com/app/id6746747903") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label(
                    title: { Text("rate_app".localized) },
                    icon: {
                        Image(systemName: "star.fill")
                            .withIOSSettingsIcon(lightColors: [
                                Color(#colorLiteral(red: 1, green: 0.8, blue: 0.2, alpha: 1)),
                                Color(#colorLiteral(red: 0.8, green: 0.5333333333, blue: 0.0, alpha: 1))
                            ])
                    }
                )
                .withExternalLinkIcon()
            }
            .tint(.primary)
            
            // Share App
            ShareLink(
                item: URL(string: "https://apps.apple.com/app/id6746747903")!,
                subject: Text("share_app_subject".localized),
                message: Text("share_app_message".localized)
            ) {
                Label(
                    title: { Text("share_app".localized) },
                    icon: {
                        Image(systemName: "square.and.arrow.up.fill")
                            .withIOSSettingsIcon(lightColors: [
                                Color(#colorLiteral(red: 0.4666666667, green: 0.8666666667, blue: 0.4, alpha: 1)),
                                Color(#colorLiteral(red: 0.1176470588, green: 0.5647058824, blue: 0.1176470588, alpha: 1))
                            ])
                    }
                )
                .withExternalLinkIcon()
            }
            .tint(.primary)

            // Contact Developer
            Button {
                if let url = URL(string: "https://t.me/amanbayserkeev0377") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label(
                    title: { Text("contact_developer".localized) },
                    icon: {
                        Image(systemName: "ellipsis.message.fill")
                            .withIOSSettingsIcon(lightColors: [
                                Color(#colorLiteral(red: 0.7333333333, green: 0.4666666667, blue: 1, alpha: 1)),
                                Color(#colorLiteral(red: 0.4666666667, green: 0.1176470588, blue: 0.7333333333, alpha: 1))
                            ])
                    }
                )
                .withExternalLinkIcon()
            }
            .tint(.primary)
            
            // Report a Bug
            Button {
                if let url = URL(string: "mailto:amanbayserkeev0377@gmail.com?subject=Bug%20Report") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label(
                    title: { Text("report_bug".localized) },
                    icon: {
                        Image(systemName: "ladybug.fill")
                            .withIOSSettingsIcon(lightColors: [
                                Color(#colorLiteral(red: 1, green: 0.4, blue: 0.4, alpha: 1)),
                                Color(#colorLiteral(red: 0.7333333333, green: 0.0666666667, blue: 0.0666666667, alpha: 1))
                            ])
                    }
                )
                .withExternalLinkIcon()
            }
            .tint(.primary)
        }
        
        // MARK: - Legal (ОБНОВЛЕННЫЙ РАЗДЕЛ)
        Section(header: Text("settings_header_legal".localized)) {
            // Terms of Service - прямая ссылка
            Button {
                if let url = URL(string: "https://www.notion.so/Terms-of-Service-204d5178e65a80b89993e555ffd3511f") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label(
                    title: { Text("terms_of_service".localized) },
                    icon: {
                        Image(systemName: "text.document")
                            .withIOSSettingsIcon(lightColors: [
                                Color(#colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)),
                                Color(#colorLiteral(red: 0.3333333333, green: 0.3333333333, blue: 0.3333333333, alpha: 1))
                            ])
                    }
                )
                .withExternalLinkIcon()
            }
            .tint(.primary)
            
            // Privacy Policy - прямая ссылка
            Button {
                if let url = URL(string: "https://www.notion.so/Privacy-Policy-1ffd5178e65a80d4b255fd5491fba4a8") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label(
                    title: { Text("privacy_policy".localized) },
                    icon: {
                        Image(systemName: "lock")
                            .withIOSSettingsIcon(lightColors: [
                                Color(#colorLiteral(red: 0.5019607843, green: 0.5019607843, blue: 0.5019607843, alpha: 1)),
                                Color(#colorLiteral(red: 0.2549019608, green: 0.2549019608, blue: 0.2549019608, alpha: 1))
                            ])
                    }
                )
                .withExternalLinkIcon()
            }
            .tint(.primary)
        }
    }
}
