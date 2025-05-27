import SwiftUI
import SwiftData

struct FolderSection: View {
    @Binding var selectedFolders: Set<HabitFolder>
    
    var body: some View {
        NavigationLink {
            FolderManagementView(mode: .selection(binding: $selectedFolders))
        } label: {
            HStack {
                Label("folders".localized, systemImage: "folder")
                
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
    }
}
