import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Introduction
                Group {
                    Text("privacy_intro_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("privacy_intro_body".localized)
                }
                
                // Collected Information
                Group {
                    Text("privacy_data_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("privacy_data_body".localized)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("privacy_data_item_1".localized)
                        Text("privacy_data_item_2".localized)
                        Text("privacy_data_item_3".localized)
                    }
                }
                
                // Data Storage
                Group {
                    Text("privacy_storage_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("privacy_storage_body".localized)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("privacy_storage_item_1".localized)
                        Text("privacy_storage_item_2".localized)
                        Text("privacy_storage_item_3".localized)
                    }
                    
                    Text("privacy_storage_implication".localized)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("privacy_storage_implication_1".localized)
                        Text("privacy_storage_implication_2".localized)
                        Text("privacy_storage_implication_3".localized)
                        Text("privacy_storage_implication_4".localized)
                    }
                }
                
                // iCloud Synchronization (НОВЫЙ РАЗДЕЛ)
                Group {
                    Text("privacy_icloud_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("privacy_icloud_body".localized)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("privacy_icloud_item_1".localized)
                        Text("privacy_icloud_item_2".localized)
                        Text("privacy_icloud_item_3".localized)
                        Text("privacy_icloud_item_4".localized)
                        Text("privacy_icloud_item_5".localized)
                    }
                }
                
                // Notifications
                Group {
                    Text("privacy_notifications_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("privacy_notifications_body".localized)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("privacy_notifications_item_1".localized)
                        Text("privacy_notifications_item_2".localized)
                        Text("privacy_notifications_item_3".localized)
                    }
                }
                
                // Data Collection and Sharing
                Group {
                    Text("privacy_collection_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("privacy_collection_body".localized)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("privacy_collection_item_1".localized)
                        Text("privacy_collection_item_2".localized)
                        Text("privacy_collection_item_3".localized)
                        Text("privacy_collection_item_4".localized)
                        Text("privacy_collection_item_5".localized)
                    }
                }
                
                // Security
                Group {
                    Text("privacy_security_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("privacy_security_item_1".localized)
                        Text("privacy_security_item_2".localized)
                    }
                }
                
                // Apple Services (НОВЫЙ РАЗДЕЛ)
                Group {
                    Text("privacy_apple_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("privacy_apple_body".localized)
                }
                
                // Children's Privacy
                Group {
                    Text("privacy_children_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("privacy_children_body".localized)
                }
                
                // Policy Updates
                Group {
                    Text("privacy_changes_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("privacy_changes_body".localized)
                }
                
                // Contact Information
                Group {
                    Text("privacy_contact_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("privacy_contact_body".localized)
                    VStack(alignment: .leading, spacing: 10) {
                        Link(destination: URL(string: "mailto:amanbayserkeev0377@gmail.com")!) {
                            HStack(spacing: 5) {
                                Image(systemName: "link")
                                    .foregroundColor(.blue)
                                Text("privacy_contact_email_label".localized)
                                    .foregroundColor(.blue)
                            }
                        }
                        Link(destination: URL(string: "https://t.me/amanbayserkeev0377")!) {
                            HStack(spacing: 5) {
                                Image(systemName: "link")
                                    .foregroundColor(.blue)
                                Text("privacy_contact_telegram_label".localized)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                // Last Updated
                Group {
                    Text("privacy_updated_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("privacy_updated_date".localized)
                }
            }
            .padding()
        }
        .navigationTitle("privacy_policy".localized)
        .navigationBarTitleDisplayMode(.large)
    }
}
