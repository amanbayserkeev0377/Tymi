import SwiftUI
import SwiftData

struct NewFolderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    
    private let folder: HabitFolder?
    private let onFolderCreated: ((HabitFolder) -> Void)?
    
    @State private var name: String = ""
    @State private var selectedColor: HabitIconColor = .primary
    @State private var selectedIcon: String? = "folder"
    
    
    @FocusState private var isNameFocused: Bool
    
    init(folder: HabitFolder? = nil, onFolderCreated: ((HabitFolder) -> Void)? = nil) {
        self.folder = folder
        self.onFolderCreated = onFolderCreated
        
        if let folder = folder {
            _name = State(initialValue: folder.name)
            _selectedColor = State(initialValue: folder.color)
            _selectedIcon = State(initialValue: folder.iconName)
        }
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Label {
                            TextField("folder_name".localized, text: $name)
                                .autocorrectionDisabled()
                                .focused($isNameFocused)
                        } icon: {
                            Image(systemName: "pencil")
                        }
                    }
                }
            }
            .navigationTitle(folder == nil ? "create_folder".localized : "edit_folder".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("save".localized) {
                        saveFolder()
                    }
                    .disabled(!isFormValid)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        isNameFocused = false
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                }
            }
        }
        .onAppear {
            if folder == nil {
                isNameFocused = true
            }
        }
    }
    
    private func saveFolder() {
        if let existingFolder = folder {
            // Update existing folder - только имя
            existingFolder.update(
                name: name,
                color: .primary, // дефолтный цвет
                iconName: "folder" // дефолтная иконка
            )
            
            try? modelContext.save()
            habitsUpdateService.triggerUpdate()
            dismiss()
        } else {
            // Create new folder - только имя
            let newFolder = HabitFolder(
                name: name,
                color: .primary, // дефолтный цвет
                iconName: "folder", // дефолтная иконка
                displayOrder: 999
            )
            modelContext.insert(newFolder)
            
            do {
                try modelContext.save()
                habitsUpdateService.triggerUpdate()
                
                onFolderCreated?(newFolder)
                dismiss()
            } catch {
                print("Error saving folder: \(error)")
                dismiss()
            }
        }
    }
}
