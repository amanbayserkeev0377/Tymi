import SwiftUI

// MARK: - HabitOptionsMenu
struct HabitOptionsMenu: View {
    let onChangeValue: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Menu {
            Button(action: onChangeValue) {
                Text("Change value")
            }
            
            Button(action: onEdit) {
                Text("Edit")
            }
            
            Divider()
            
            Button(role: .destructive, action: onDelete) {
                Text("Delete")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.body.weight(.medium))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .buttonStyle(GlassButtonStyle())
    }
}

struct HabitDetailView: View {
    @StateObject private var viewModel: HabitDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showManualInput = false
    @State private var manualInputValue = ""
    
    var onEdit: ((Habit) -> Void)?
    var onDelete: ((Habit) -> Void)?
    var onUpdate: ((Habit, Double) -> Void)?
    var onComplete: ((Habit) -> Void)?
    
    init(
        habit: Habit,
        habitStore: HabitStoreManager,
        onEdit: ((Habit) -> Void)? = nil,
        onDelete: ((Habit) -> Void)? = nil,
        onUpdate: ((Habit, Double) -> Void)? = nil,
        onComplete: ((Habit) -> Void)? = nil
    ) {
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onUpdate = onUpdate
        self.onComplete = onComplete
        
        let vm = HabitDetailViewModel(habit: habit, habitStore: habitStore)
        _viewModel = StateObject(wrappedValue: vm)
        
        vm.onUpdate = { [weak vm] value in
            guard let habit = vm?.habit else { return }
            onUpdate?(habit, value)
        }
        
        vm.onComplete = { [weak vm] in
            guard let habit = vm?.habit else { return }
            onComplete?(habit)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Progress")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(viewModel.currentValue)) / \(Int(viewModel.habit.goal))")
                                .foregroundStyle(.secondary)
                        }
                        
                        ProgressView(value: viewModel.progress)
                            .tint(viewModel.isCompleted ? .green : .blue)
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    if viewModel.habit.type == .count {
                        Stepper("Count", value: $viewModel.currentValue, in: 0...Double.infinity, step: 1)
                    } else {
                        HStack {
                            Text("Timer")
                            Spacer()
                            Button {
                                viewModel.toggleTimer()
                            } label: {
                                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                    .foregroundStyle(viewModel.isPlaying ? .red : .green)
                            }
                        }
                    }
                    
                    Button("Reset") {
                        viewModel.reset()
                    }
                    .foregroundStyle(.red)
                }
                
                Section {
                    Button("Change Value") {
                        showManualInput = true
                    }
                    
                    Button("Edit Habit") {
                        onEdit?(viewModel.habit)
                    }
                    
                    Button("Delete Habit", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
            }
            .navigationTitle(viewModel.habit.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Habit", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete?(viewModel.habit)
                }
            } message: {
                Text("Are you sure you want to delete this habit? This action cannot be undone.")
            }
            .alert("Change Value", isPresented: $showManualInput) {
                TextField("Value", text: $manualInputValue)
                    .keyboardType(.numberPad)
                
                Button("Cancel", role: .cancel) { }
                Button("OK") {
                    if let value = Double(manualInputValue) {
                        viewModel.setValue(value)
                    }
                }
            } message: {
                Text("Enter a new value for this habit")
            }
        }
    }
}

// MARK: - ExpandedControls
struct ExpandedControls: View {
    let onDecrementLarge: () -> Void
    let onDecrementSmall: () -> Void
    let onIncrementSmall: () -> Void
    let onIncrementLarge: () -> Void
    let onManualInput: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Button(action: onDecrementLarge) {
                    Text("-30")
                        .font(.body.weight(.medium))
                }
                .buttonStyle(GlassButtonStyle(size: 44))
                
                Button(action: onDecrementSmall) {
                    Text("-10")
                        .font(.body.weight(.medium))
                }
                .buttonStyle(GlassButtonStyle(size: 44))
                
                Button(action: onManualInput) {
                    Image(systemName: "arrow.up")
                        .font(.body.weight(.medium))
                }
                .buttonStyle(GlassButtonStyle(size: 44))
                
                Button(action: onIncrementSmall) {
                    Text("+10")
                        .font(.body.weight(.medium))
                }
                .buttonStyle(GlassButtonStyle(size: 44))
                
                Button(action: onIncrementLarge) {
                    Text("+30")
                        .font(.body.weight(.medium))
                }
                .buttonStyle(GlassButtonStyle(size: 44))
            }
        }
    }
}

#Preview {
    HabitDetailView(
        habit: Habit(name: "Morning Workout"),
        habitStore: HabitStoreManager()
    )
}
