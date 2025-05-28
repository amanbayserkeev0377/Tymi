import SwiftUI
import CloudKit

struct CloudKitSyncView: View {
    @State private var cloudKitStatus: CloudKitStatus = .checking
    
    private enum CloudKitStatus {
        case checking, available, unavailable, restricted, error(String)
        
        var statusInfo: (text: String, color: Color, icon: String) {
            switch self {
            case .checking:
                return ("icloud_checking_status".localized, .secondary, "icloud.fill")
            case .available:
                return ("icloud_sync_active".localized, .green, "checkmark.icloud.fill")
            case .unavailable:
                return ("icloud_not_signed_in".localized, .orange, "person.icloud.fill")
            case .restricted:
                return ("icloud_restricted".localized, .red, "exclamationmark.icloud.fill")
            case .error(let message):
                return (message, .red, "xmark.icloud.fill")
            }
        }
    }
    
    var body: some View {
        List {
            // Status Section
            Section {
                HStack {
                    statusIcon(cloudKitStatus.statusInfo.icon)
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
                    icon: "icloud.and.arrow.up.fill",
                    title: "icloud_automatic_backup".localized,
                    description: "icloud_automatic_backup_desc".localized
                )
                
                SyncInfoRow(
                    icon: "arrow.trianglehead.2.clockwise.rotate.90.icloud.fill",
                    title: "icloud_cross_device_sync".localized,
                    description: "icloud_cross_device_sync_desc".localized
                )
                
                SyncInfoRow(
                    icon: "lock.icloud.fill",
                    title: "icloud_private_secure".localized,
                    description: "icloud_private_secure_desc".localized
                )
            }
            
            // Troubleshooting
            if case .unavailable = cloudKitStatus {
                Section {
                    HStack {
                        troubleshootingIcon()
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
    
    // MARK: - Icon Views
    @ViewBuilder
    private func statusIcon(_ iconName: String) -> some View {
        switch iconName {
        case "icloud.fill":
            Image(systemName: iconName)
                .withGradientIcon(
                    colors: [
                        Color(#colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)),
                        Color(#colorLiteral(red: 0.4, green: 0.4, blue: 0.4, alpha: 1))
                    ],
                    startPoint: .top,
                    endPoint: .bottom,
                    fontSize: 20
                )
                
        case "checkmark.icloud.fill":
            Image(systemName: iconName)
                .withGradientIcon(
                    colors: [
                        Color(#colorLiteral(red: 0.1960784314, green: 0.8431372549, blue: 0.2941176471, alpha: 1)),
                        Color(#colorLiteral(red: 0.1333333333, green: 0.5882352941, blue: 0.1333333333, alpha: 1))
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing,
                    fontSize: 20
                )
                
        case "person.icloud.fill":
            Image(systemName: iconName)
                .withGradientIcon(
                    colors: [
                        Color(#colorLiteral(red: 1, green: 0.8, blue: 0.0, alpha: 1)),
                        Color(#colorLiteral(red: 0.8, green: 0.5, blue: 0.0, alpha: 1))
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing,
                    fontSize: 20
                )
                
        case "exclamationmark.icloud.fill":
            Image(systemName: iconName)
                .withGradientIcon(
                    colors: [
                        Color(#colorLiteral(red: 1, green: 0.4, blue: 0.4, alpha: 1)),
                        Color(#colorLiteral(red: 0.8, green: 0.2, blue: 0.2, alpha: 1))
                    ],
                    startPoint: .top,
                    endPoint: .bottom,
                    fontSize: 20
                )
                
        case "xmark.icloud.fill":
            Image(systemName: iconName)
                .withGradientIcon(
                    colors: [
                        Color(#colorLiteral(red: 1, green: 0.3, blue: 0.3, alpha: 1)),
                        Color(#colorLiteral(red: 0.7, green: 0.1, blue: 0.1, alpha: 1))
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing,
                    fontSize: 20
                )
                
        default:
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func troubleshootingIcon() -> some View {
        Image(systemName: "wrench.adjustable.fill")
            .withGradientIcon(
                colors: [
                    Color(#colorLiteral(red: 0.5019607843, green: 0.5019607843, blue: 0.5019607843, alpha: 1)),
                    Color(#colorLiteral(red: 0.3019607843, green: 0.3019607843, blue: 0.3019607843, alpha: 1))
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing,
                fontSize: 20
            )
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
}

// MARK: - Helper Views
struct SyncInfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            iconWithGradient(icon)
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
    
    @ViewBuilder
    private func iconWithGradient(_ iconName: String) -> some View {
        switch iconName {
        case "icloud.and.arrow.up.fill":
            Image(systemName: iconName)
                .withGradientIcon(
                    colors: [
                        Color(#colorLiteral(red: 0.1960784314, green: 0.8431372549, blue: 0.2941176471, alpha: 1)),
                        Color(#colorLiteral(red: 0.1333333333, green: 0.5882352941, blue: 0.1333333333, alpha: 1))
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing,
                    fontSize: 18
                )
                
        case "arrow.trianglehead.2.clockwise.rotate.90.icloud.fill":
            Image(systemName: iconName)
                .withGradientIcon(
                    colors: [
                        Color(#colorLiteral(red: 0.3411764706, green: 0.6235294118, blue: 1, alpha: 1)),
                        Color(#colorLiteral(red: 0.0, green: 0.3803921569, blue: 0.7647058824, alpha: 1))
                    ],
                    startPoint: .top,
                    endPoint: .bottom,
                    fontSize: 18
                )
                
        case "lock.icloud.fill":
            Image(systemName: iconName)
                .withGradientIcon(
                    colors: [
                        Color(#colorLiteral(red: 1, green: 0.5843137255, blue: 0.0, alpha: 1)),
                        Color(#colorLiteral(red: 0.8549019608, green: 0.2470588235, blue: 0.1176470588, alpha: 1))
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing,
                    fontSize: 18
                )
                
        default:
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}
