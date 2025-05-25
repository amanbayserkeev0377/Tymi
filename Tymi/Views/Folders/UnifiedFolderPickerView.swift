import SwiftUI
import SwiftData

struct UnifiedFolderPickerView: View {
    // For multiple selection (NewHabitView)
    @Binding var selectedFolders: Set<HabitFolder>
    // For settings navigation
    let isFromSettings: Bool
    // For Move to Folder modal
    let isMoveToFolderMode: Bool
    // Callback for folder selection
    private let onFoldersSelected: ((Set<HabitFolder>) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    
    @Query(sort: [SortDescriptor(\HabitFolder.displayOrder)])
    private var folders: [HabitFolder]
    
    @State private var isEditMode = false
    @State private var isShowingNewFolderSheet = false
    @State private var folderToEdit: HabitFolder?
    @State private var folderToDelete: HabitFolder?
    @State private var isDeleteAlertPresented = false
    
    // For NewHabitView NavigationLink
    init(selectedFolders: Binding<Set<HabitFolder>>) {
        self._selectedFolders = selectedFolders
        self.isFromSettings = false
        self.isMoveToFolderMode = false
        self.onFoldersSelected = nil
    }
    
    // For Settings navigation
    init() {
        self._selectedFolders = .constant(Set<HabitFolder>())
        self.isFromSettings = true
        self.isMoveToFolderMode = false
        self.onFoldersSelected = nil
    }
    
    // For Move to Folder modal with callback
    init(selectedFolders: Binding<Set<HabitFolder>>, onFoldersSelected: @escaping (Set<HabitFolder>) -> Void) {
        self._selectedFolders = selectedFolders
        self.isFromSettings = false
        self.isMoveToFolderMode = true
        self.onFoldersSelected = onFoldersSelected
    }
    
    var body: some View {
        List {
            if folders.isEmpty {
                // No folders yet - show create folder prominently
                Section {
                    Button {
                        isShowingNewFolderSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                                .frame(width: 30, height: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("create_first_folder".localized)
                                    .font(.headline)
                                    .foregroundStyle(.blue)
                                
                                Text("organize_habits_with_folders".localized)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            } else {
                // Show existing folders
                Section {
                    ForEach(folders) { folder in
                        if isFromSettings {
                            // Settings mode - show folder details
                            settingsFolderRow(folder: folder)
                        } else {
                            // Selection mode - show checkboxes
                            selectionFolderRow(folder: folder)
                        }
                    }
                    .onMove(perform: isEditMode ? moveFolders : nil)
                    .onDelete(perform: isEditMode ? deleteFolders : nil)
                }
                
                // Add Folder button at the end when folders exist
                Section {
                    Button {
                        isShowingNewFolderSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                                .frame(width: 30, height: 30)
                            
                            Text("add_folder".localized)
                                .font(.headline)
                                .foregroundStyle(.blue)
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle(isFromSettings ? "folders".localized : "add_to_folders".localized)
        .navigationBarTitleDisplayMode(isFromSettings ? .large : .inline)
        .toolbar {
            if isMoveToFolderMode {
                // Move to Folder modal - Save/Cancel buttons
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("save".localized) {
                        onFoldersSelected?(selectedFolders)
                        dismiss()
                    }
                }
            } else if isFromSettings && !folders.isEmpty {
                // Settings toolbar with Edit/Done (только когда есть папки)
                ToolbarItem(placement: .primaryAction) {
                    Button(isEditMode ? "done".localized : "edit".localized) {
                        withAnimation {
                            isEditMode.toggle()
                        }
                    }
                }
            }
            // Для NewHabitView NavigationLink - никаких toolbar кнопок!
        }
        .environment(\.editMode, isEditMode ? .constant(.active) : .constant(.inactive))
        .sheet(isPresented: $isShowingNewFolderSheet) {
            NewFolderView()
        }
        .sheet(item: $folderToEdit) { folder in
            NewFolderView(folder: folder)
        }
        .alert("delete_folder_confirmation".localized, isPresented: $isDeleteAlertPresented) {
            Button("cancel".localized, role: .cancel) {
                folderToDelete = nil
            }
            Button("delete".localized, role: .destructive) {
                if let folder = folderToDelete {
                    deleteFolder(folder)
                }
                folderToDelete = nil
            }
        } message: {
            if let folder = folderToDelete {
                Text("delete_folder_description".localized(with: folder.habitsCount))
            }
        }
    }
    
    // MARK: - Row Views
    
    @ViewBuilder
    private func settingsFolderRow(folder: HabitFolder) -> some View {
        if isEditMode {
            // Edit mode - simple row for reordering/deleting
            HStack {
                if let iconName = folder.iconName {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundStyle(folder.color.color)
                        .frame(width: 30, height: 30)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(folder.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("habits_count".localized(with: folder.habitsCount))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        } else {
            // Normal mode - tappable row
            Button {
                folderToEdit = folder
            } label: {
                HStack {
                    if let iconName = folder.iconName {
                        Image(systemName: iconName)
                            .font(.title2)
                            .foregroundStyle(folder.color.color)
                            .frame(width: 30, height: 30)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(folder.name)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text("habits_count".localized(with: folder.habitsCount))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    private func selectionFolderRow(folder: HabitFolder) -> some View {
        Button {
            toggleFolderSelection(folder)
        } label: {
            HStack {
                if let iconName = folder.iconName {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundStyle(folder.color.color)
                        .frame(width: 30, height: 30)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(folder.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text("habits_count".localized(with: folder.habitsCount))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if selectedFolders.contains(folder) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                        .font(.headline)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Methods
    
    private func toggleFolderSelection(_ folder: HabitFolder) {
        if selectedFolders.contains(folder) {
            selectedFolders.remove(folder)
        } else {
            selectedFolders.insert(folder)
        }
        HapticManager.shared.playSelection()
    }
    
    private func moveFolders(from source: IndexSet, to destination: Int) {
        var foldersArray = Array(folders)
        foldersArray.move(fromOffsets: source, toOffset: destination)
        
        // Update display order
        for (index, folder) in foldersArray.enumerated() {
            folder.displayOrder = index
        }
        
        try? modelContext.save()
        habitsUpdateService.triggerUpdate()
        HapticManager.shared.playSelection()
    }
    
    private func deleteFolders(at offsets: IndexSet) {
        for index in offsets {
            let folder = folders[index]
            folderToDelete = folder
            isDeleteAlertPresented = true
            break // Handle one at a time for confirmation
        }
    }
    
    private func deleteFolder(_ folder: HabitFolder) {
        // Move all habits from this folder to no folder
        if let habits = folder.habits {
            for habit in habits {
                habit.removeFromFolder(folder)
            }
        }
        
        // Delete the folder
        modelContext.delete(folder)
        
        try? modelContext.save()
        habitsUpdateService.triggerUpdate()
        HapticManager.shared.play(.error)
    }
}
