import SwiftUI
import SwiftData

struct FolderSection: View {
    @Binding var selectedFolders: Set<HabitFolder>
    
    var body: some View {
        NavigationLink {
            FolderManagementView(mode: .selection(binding: $selectedFolders))
        } label: {
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
    }
}
