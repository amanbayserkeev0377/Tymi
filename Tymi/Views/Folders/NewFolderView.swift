import SwiftUI
import SwiftData

struct NewFolderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    
    private let folder: HabitFolder?
    private let onFolderCreated: ((HabitFolder) -> Void)?
    
    @State private var name: String = ""
    @FocusState private var isNameFocused: Bool
    
    init(folder: HabitFolder? = nil, onFolderCreated: ((HabitFolder) -> Void)? = nil) {
        self.folder = folder
        self.onFolderCreated = onFolderCreated
        
        if let folder = folder {
            _name = State(initialValue: folder.name)
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
                            TextField("folders_folder_name".localized, text: $name)
                                .autocorrectionDisabled()
                                .focused($isNameFocused)
                        } icon: {
                            Image(systemName: "pencil")
                        }
                    }
                }
            }
            .navigationTitle(folder == nil ? "folders_new_folder".localized : "folders_edit_folder".localized)
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
            existingFolder.name = name
            
            try? modelContext.save()
            habitsUpdateService.triggerUpdate()
            dismiss()
        } else {
            let newFolder = HabitFolder(name: name, displayOrder: 999)
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
