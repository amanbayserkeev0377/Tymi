import SwiftUI
import SwiftData

struct FolderSection: View {
    @Binding var selectedFolders: Set<HabitFolder>
    let allFolders: [HabitFolder]
    
    var body: some View {
        NavigationLink {
            UnifiedFolderPickerView(selectedFolders: $selectedFolders)
        } label: {
            HStack {
                Label {
                    Text("folders".localized)
                } icon: {
                    Image(systemName: "folder")
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    if selectedFolders.isEmpty {
                        Text("no_folders_selected".localized)
                            .foregroundStyle(.secondary)
                    } else if selectedFolders.count == 1 {
                        Text(selectedFolders.first!.name)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("folders_count_selected".localized(with: selectedFolders.count))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
