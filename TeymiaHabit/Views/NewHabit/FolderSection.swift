import SwiftUI
import SwiftData

struct FolderSection: View {
    @Binding var selectedFolders: Set<HabitFolder>
    @Environment(ProManager.self) private var proManager
    @State private var showingPaywall = false
    
    var body: some View {
        if proManager.canUseFolders {
            // Pro users - normal folder selection
            NavigationLink {
                FolderManagementView(mode: .selection(binding: $selectedFolders))
            } label: {
                folderContent
            }
        } else {
            // Free users - show Pro badge and paywall
            Button {
                showingPaywall = true
            } label: {
                folderContentWithProBadge
            }
            .tint(.primary)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }
    
    // MARK: - Content Views
    
    private var folderContent: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder")
                .foregroundStyle(AppColorManager.shared.selectedColor.color)
                .font(.system(size: 22))
                .frame(width: 30)
                .clipped()
            Text("folders".localized)
            
            Spacer()
            
            if selectedFolders.isEmpty {
                Text("folders_none_selected".localized)
                    .foregroundStyle(.secondary)
            } else {
                Text(selectedFolders.map { $0.name }.joined(separator: ", "))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
    
    private var folderContentWithProBadge: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder")
                .foregroundStyle(AppColorManager.shared.selectedColor.color.opacity(0.5))
                .font(.system(size: 22))
                .frame(width: 30)
                .clipped()
            
            Text("folders".localized)
                .foregroundStyle(.primary)
            
            Spacer()
            
            // Pro badge
            ProLockBadge()
        }
    }
}
