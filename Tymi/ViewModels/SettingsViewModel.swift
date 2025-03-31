import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @AppStorage("enableReminders") private var enableReminders = false
    
    // MARK: - Social Links
    private let appStoreURL = URL(string: "https://apps.apple.com/app/id123456789")!
    private let emailURL = URL(string: "mailto:hello@tymiapp.com")!
    private let xURL = URL(string: "https://x.com/tymiapp")!
    private let instagramURL = URL(string: "https://instagram.com/tymiapp")!
    private let websiteURL = URL(string: "https://tymiapp.com")!
    
    var isRemindersEnabled: Binding<Bool> {
        Binding(
            get: { self.enableReminders },
            set: { self.enableReminders = $0 }
        )
    }
    
    func openAppStore() {
        UIApplication.shared.open(appStoreURL)
    }
    
    func openEmail() {
        UIApplication.shared.open(emailURL)
    }
    
    func openX() {
        UIApplication.shared.open(xURL)
    }
    
    func openInstagram() {
        UIApplication.shared.open(instagramURL)
    }
    
    func openWebsite() {
        UIApplication.shared.open(websiteURL)
    }
} 