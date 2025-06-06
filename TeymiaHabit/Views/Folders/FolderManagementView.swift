import SwiftUI
import SwiftData

enum FolderViewMode {
    case selection(binding: Binding<Set<HabitFolder>>)  // NewHabitView - tap = выбор
    case management                                      // Settings - tap = редактирование
}

struct FolderManagementView: View {
    let mode: FolderViewMode
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    @Environment(\.editMode) private var editMode
    
    @Query(sort: [SortDescriptor(\HabitFolder.displayOrder)])
    private var folders: [HabitFolder]
    
    @State private var isShowingNewFolderSheet = false
    @State private var folderToEdit: HabitFolder?
    @State private var selectedForDeletion: Set<HabitFolder.ID> = []
    @State private var isDeleteSelectedAlertPresented = false
    @State private var folderToDelete: HabitFolder?
    @State private var isDeleteSingleAlertPresented = false
    
    var body: some View {
        mainContent
            .listStyle(.insetGrouped)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
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
            .deleteMultipleFoldersAlert(
                isPresented: $isDeleteSelectedAlertPresented,
                foldersCount: selectedForDeletion.count,
                onDelete: deleteSelectedFolders
            )
            .deleteSingleFolderAlert(
                isPresented: $isDeleteSingleAlertPresented,
                folderName: folderToDelete?.name ?? "",
                onDelete: {
                    if let folder = folderToDelete {
                        deleteFolder(folder)
                    }
                    folderToDelete = nil
                }
            )
    }
    
    // MARK: - Main Content
    @ViewBuilder
    private var mainContent: some View {
        Group {
            if editMode?.wrappedValue == .active {
                List(selection: $selectedForDeletion) {
                    listContent
                }
            } else {
                List {
                    listContent
                }
            }
        }
    }
    
    // MARK: - Toolbar Content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if !folders.isEmpty {
            ToolbarItem(placement: .primaryAction) {
                EditButton()
            }
        }
        
        if !selectedForDeletion.isEmpty {
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Spacer()
                    Button {
                        isDeleteSelectedAlertPresented = true
                    } label: {
                        HStack {
                            Text("button_delete".localized)
                            Image(systemName: "trash")
                        }
                    }
                    .tint(.red)
                }
            }
        }
    }
    
    // MARK: - Navigation Title
    private var navigationTitle: String {
        if editMode?.wrappedValue == .active && !selectedForDeletion.isEmpty {
            return "items_selected".localized(with: selectedForDeletion.count)
        } else {
            return "folders".localized
        }
    }
    
    // MARK: - List Content
    @ViewBuilder
    private var listContent: some View {
        Section(
            footer: shouldShowEditFooter ? Text("folders_edit_footer".localized) : nil
        ) {
            // Create folder button - показывать только если НЕ в edit mode
            if editMode?.wrappedValue != .active {
                createFolderButton
            }
            
            if !folders.isEmpty {
                // Folders list
                ForEach(folders) { folder in
                    folderRow(folder)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            // Delete action (red) - показывать только если НЕ в edit mode
                            if editMode?.wrappedValue != .active {
                                Button(role: .destructive) {
                                    folderToDelete = folder
                                    isDeleteSingleAlertPresented = true
                                } label: {
                                    Label("button_delete".localized, systemImage: "trash")
                                }
                                .tint(.red)
                            }
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
                Text("folders_create_folder".localized)
                Spacer()
            }
        }
    }
    
    // MARK: - Folder Row
    @ViewBuilder
    private func folderRow(_ folder: HabitFolder) -> some View {
        Button {
            // Только если НЕ в edit mode
            if editMode?.wrappedValue != .active {
                withAnimation(.easeInOut) {
                    handleFolderTap(folder)
                }
            }
        } label: {
            HStack {
                Text(folder.name)
                    .tint(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                // Разные trailing элементы в зависимости от режима
                if editMode?.wrappedValue != .active {
                    switch mode {
                    case .selection(let binding):
                        Image(systemName: "checkmark")
                            .opacity(binding.wrappedValue.contains(folder) ? 1 : 0)
                            .animation(.easeInOut, value: binding.wrappedValue.contains(folder))
                        
                    case .management:
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color(uiColor: .systemGray3))
                            .font(.footnote)
                            .fontWeight(.bold)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var shouldShowEditFooter: Bool {
        if case .selection = mode {
            return !folders.isEmpty
        }
        return false
    }
    
    // MARK: - Helper Methods
    
    private func handleFolderTap(_ folder: HabitFolder) {
        switch mode {
        case .selection(let binding):
            // Режим выбора - toggle папку
            if binding.wrappedValue.contains(folder) {
                binding.wrappedValue.remove(folder)
            } else {
                binding.wrappedValue.insert(folder)
            }
            HapticManager.shared.playSelection()
            
        case .management:
            // Режим управления - редактировать
            folderToEdit = folder
        }
    }
    
    private func deleteFolder(_ folder: HabitFolder) {
        // Удаляем папку из всех привычек
        if let habits = folder.habits {
            for habit in habits {
                habit.removeFromFolder(folder)
            }
        }
        
        // Удаляем папку
        modelContext.delete(folder)
        
        try? modelContext.save()
        habitsUpdateService.triggerUpdate()
        HapticManager.shared.play(.error)
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
