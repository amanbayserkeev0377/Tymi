import SwiftUI
import SwiftData

struct MoveToFolderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(HabitsUpdateService.self) private var habitsUpdateService
    
    let habits: [Habit]
    @State private var selectedFolders: Set<HabitFolder> = []
    
    @Query(sort: [SortDescriptor(\HabitFolder.displayOrder)])
    private var allFolders: [HabitFolder]
    
    var body: some View {
        NavigationStack {
            List {
                // No folder option
                Button {
                    toggleNoFolder()
                } label: {
                    HStack {
                        Text("no_folder".localized)
                        Spacer()
                        Image(systemName: "checkmark")
                            .opacity(selectedFolders.isEmpty ? 1 : 0)
                    }
                }
                
                // Folders list
                ForEach(allFolders) { folder in
                    Button {
                        toggleFolder(folder)
                    } label: {
                        HStack {
                            Text(folder.name)
                            Spacer()
                            Image(systemName: "checkmark")
                                .opacity(selectedFolders.contains(folder) ? 1 : 0)
                        }
                    }
                }
            }
            .navigationTitle("move_to_folder".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("move".localized) {
                        moveHabits()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleNoFolder() {
        selectedFolders.removeAll()
    }
    
    private func toggleFolder(_ folder: HabitFolder) {
        if selectedFolders.contains(folder) {
            selectedFolders.remove(folder)
        } else {
            selectedFolders.insert(folder)
        }
    }
    
    private func moveHabits() {
        for habit in habits {
            habit.removeFromAllFolders()
            for folder in selectedFolders {
                habit.addToFolder(folder)
            }
        }
        
        try? modelContext.save()
        habitsUpdateService.triggerUpdate()
        HapticManager.shared.play(.success)
        
        dismiss()
    }
} 
