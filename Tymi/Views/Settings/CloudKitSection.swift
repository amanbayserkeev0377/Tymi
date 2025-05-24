import SwiftUI
import CloudKit

struct CloudKitSyncView: View {
    @State private var cloudKitStatus: CloudKitStatus = .checking
    @State private var userAccountStatus: String = ""
    
    private enum CloudKitStatus {
        case checking, available, unavailable, restricted, error(String)
        
        var statusInfo: (text: String, color: Color, icon: String) {
            switch self {
            case .checking:
                return ("icloud_checking_status".localized, .secondary, "icloud")
            case .available:
                return ("icloud_sync_active".localized, .green, "checkmark.icloud")
            case .unavailable:
                return ("icloud_not_signed_in".localized, .orange, "person.icloud")
            case .restricted:
                return ("icloud_restricted".localized, .red, "exclamationmark.icloud")
            case .error(let message):
                return (message, .red, "xmark.icloud")
            }
        }
    }
    
    var body: some View {
        List {
            // Status Section
            Section {
                HStack {
                    Image(systemName: cloudKitStatus.statusInfo.icon)
                        .font(.title2)
                        .foregroundStyle(cloudKitStatus.statusInfo.color)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("icloud_sync_status".localized)
                            .font(.headline)
                        
                        Text(cloudKitStatus.statusInfo.text)
                            .font(.subheadline)
                            .foregroundStyle(cloudKitStatus.statusInfo.color)
                    }
                    
                    Spacer()
                    
                    if case .checking = cloudKitStatus {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(.vertical, 2)
            }
            
            // How it works
            Section("icloud_how_sync_works".localized) {
                SyncInfoRow(
                    icon: "icloud.and.arrow.up",
                    title: "icloud_automatic_backup".localized,
                    description: "icloud_automatic_backup_desc".localized
                )
                
                SyncInfoRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "icloud_cross_device_sync".localized,
                    description: "icloud_cross_device_sync_desc".localized
                )
                
                SyncInfoRow(
                    icon: "lock.shield",
                    title: "icloud_private_secure".localized,
                    description: "icloud_private_secure_desc".localized
                )
            }
            
            // Troubleshooting
            if case .unavailable = cloudKitStatus {
                Section {
                    HStack {
                        Image(systemName: "wrench.adjustable")
                            .font(.title2)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("icloud_signin_required".localized)
                                .font(.subheadline)
                            
                            Text("icloud_signin_steps".localized)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("icloud_troubleshooting".localized)
                }
            }
        }
        .navigationTitle("icloud_sync".localized)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            checkCloudKitStatus()
        }
    }
    
    // MARK: - Helper Methods
    private func checkCloudKitStatus() {
        Task {
            await checkAccountStatus()
        }
    }
    
    @MainActor
    private func checkAccountStatus() async {
        do {
            let container = CKContainer(identifier: "iCloud.com.amanbayserkeev.tymi")
            let accountStatus = try await container.accountStatus()
            
            switch accountStatus {
            case .available:
                await fetchUserInfo(container: container)
                cloudKitStatus = .available
            case .noAccount:
                cloudKitStatus = .unavailable
            case .restricted:
                cloudKitStatus = .restricted
            case .couldNotDetermine:
                cloudKitStatus = .error("icloud_status_unknown".localized)
            case .temporarilyUnavailable:
                cloudKitStatus = .error("icloud_temporarily_unavailable".localized)
            @unknown default:
                cloudKitStatus = .error("icloud_unknown_error".localized)
            }
        } catch {
            cloudKitStatus = .error("icloud_check_failed".localized)
        }
    }
    
    private func fetchUserInfo(container: CKContainer) async {
        do {
            let userRecordID = try await container.userRecordID()
            let recordName = userRecordID.recordName
            // Показываем замаскированную версию для приватности
            if recordName.count > 8 {
                let prefix = String(recordName.prefix(4))
                let suffix = String(recordName.suffix(4))
                userAccountStatus = "\(prefix)•••\(suffix)"
            } else {
                userAccountStatus = recordName
            }
        } catch {
            userAccountStatus = ""
        }
    }
}

// MARK: - Helper Views
struct SyncInfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
