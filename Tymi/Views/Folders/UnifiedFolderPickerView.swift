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
    @Environment(\.editMode) private var editMode
    @ObservedObject private var colorManager = AppColorManager.shared
    
    @Query(sort: [SortDescriptor(\HabitFolder.displayOrder)])
    private var folders: [HabitFolder]
    
    @State private var isShowingNewFolderSheet = false
    @State private var folderToEdit: HabitFolder?
    @State private var selectedForDeletion: Set<HabitFolder.ID> = []
    @State private var isDeleteSelectedAlertPresented = false
    
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
        Group {
            if isFromSettings && editMode?.wrappedValue == .active {
                // В edit mode - с selection
                List(selection: $selectedForDeletion) {
                    listContent
                }
            } else {
                // В обычном режиме - без selection
                List {
                    listContent
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(isFromSettings ? "folders".localized : "add_to_folders".localized)
        .navigationBarTitleDisplayMode(isFromSettings ? .large : .inline)
        .toolbar {
            if isMoveToFolderMode {
                // Move to Folder modal buttons
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save".localized) {
                        onFoldersSelected?(selectedFolders)
                        dismiss()
                    }
                }
            } else if isFromSettings && !folders.isEmpty {
                // НАТИВНАЯ EditButton
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !selectedForDeletion.isEmpty && isFromSettings {
                bottomDeleteToolbar
            }
        }
        .onChange(of: editMode?.wrappedValue) { _, newValue in
            if newValue != .active {
                selectedForDeletion.removeAll()
            }
        }
        .sheet(isPresented: $isShowingNewFolderSheet) {
            NewFolderView()
        }
        .sheet(item: $folderToEdit) { folder in
            NewFolderView(folder: folder)
        }
        .alert("delete_folders_confirmation".localized, isPresented: $isDeleteSelectedAlertPresented) {
            Button("cancel".localized, role: .cancel) {}
            Button("delete".localized, role: .destructive) {
                deleteSelectedFolders()
            }
        } message: {
            Text("delete_folders_message".localized(with: selectedForDeletion.count))
        }
    }
    
    // MARK: - List Content
    @ViewBuilder
    private var listContent: some View {
        Section(
            header: Text("folders".localized),
            footer: shouldShowEditFooter ? Text("folders_edit_footer".localized) : nil
        ) {
            // Create folder button
            createFolderButton
            
            if !folders.isEmpty {
                // Folders list
                ForEach(folders) { folder in
                    if isFromSettings {
                        folderRow(folder)
                    } else {
                        selectionFolderRow(folder: folder)
                    }
                }
                .onMove(perform: moveFolders)
            }
        }
    }
    
    // MARK: - Create Folder Button
    @ViewBuilder
    private var createFolderButton: some View {
        Button {
            isShowingNewFolderSheet = true
        } label: {
            HStack {
                Image(systemName: "plus")
                
                Text("create_folder".localized)
                    .font(.headline)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Folder Row
    @ViewBuilder
    private func folderRow(_ folder: HabitFolder) -> some View {
        Button {
            // В edit mode не открываем редактирование
            if editMode?.wrappedValue != .active {
                folderToEdit = folder
            }
        } label: {
            HStack {
                Text(folder.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                // Убираем chevron в edit mode
                if editMode?.wrappedValue != .active {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color(.systemGray2))
                        .font(.caption)
                }
            }
        }
        .buttonStyle(.borderless)
    }
    
    @ViewBuilder
    private func selectionFolderRow(folder: HabitFolder) -> some View {
        Button {
            toggleFolderSelection(folder)
        } label: {
            HStack {
                Text(folder.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                if selectedFolders.contains(folder) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                        .font(.headline)
                }
            }
        }
        .buttonStyle(.borderless)
    }
    
    // MARK: - Bottom Toolbar
    @ViewBuilder
    private var bottomDeleteToolbar: some View {
        HStack {
            Text("items_selected".localized(with: selectedForDeletion.count))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button("delete".localized) {
                isDeleteSelectedAlertPresented = true
            }
            .foregroundStyle(.red)
        }
        .padding()
        .background(.regularMaterial, in: Rectangle())
    }
    
    // MARK: - Computed Properties
    private var shouldShowEditFooter: Bool {
        return isFromSettings && !folders.isEmpty
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
    
    private func deleteSelectedFolders() {
        let foldersToDelete = folders.filter { selectedForDeletion.contains($0.id) }
        
        for folder in foldersToDelete {
            if let habits = folder.habits {
                for habit in habits {
                    habit.removeFromFolder(folder)
                }
            }
            modelContext.delete(folder)
        }
        
        try? modelContext.save()
        habitsUpdateService.triggerUpdate()
        HapticManager.shared.play(.error)
        
        selectedForDeletion.removeAll()
    }
    
    private func moveFolders(from source: IndexSet, to destination: Int) {
        var foldersArray = Array(folders)
        foldersArray.move(fromOffsets: source, toOffset: destination)
        
        for (index, folder) in foldersArray.enumerated() {
            folder.displayOrder = index
        }
        
        try? modelContext.save()
        habitsUpdateService.triggerUpdate()
        HapticManager.shared.playSelection()
    }
}
