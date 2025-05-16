import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Introduction
                Group {
                    Text("tos_intro_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("tos_intro_body".localized)
                }
                
                // Warranty Disclaimer
                Group {
                    Text("tos_warranty_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("tos_warranty_body".localized)
                }
                
                // Risk and Liability
                Group {
                    Text("tos_risk_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("tos_risk_body".localized)
                }
                
                // Updates
                Group {
                    Text("tos_updates_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("tos_updates_body".localized)
                }
                
                // Data Privacy
                Group {
                    Text("tos_privacy_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("tos_privacy_body".localized)
                }
                
                // Contact
                Group {
                    Text("tos_contact_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("tos_contact_body".localized)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Link(destination: URL(string: "mailto:amanbayserkeev0377@gmail.com")!) {
                            HStack(spacing: 5) {
                                Image(systemName: "link")
                                    .foregroundColor(.blue)
                                Text("tos_contact_email_label".localized)
                                    .foregroundColor(.blue)
                            }
                        }
                        Link(destination: URL(string: "https://t.me/amanbayserkeev0377")!) {
                            HStack(spacing: 5) {
                                Image(systemName: "link")
                                    .foregroundColor(.blue)
                                Text("tos_contact_telegram_label".localized)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("terms_of_service".localized)
        .navigationBarTitleDisplayMode(.large)
    }
}
