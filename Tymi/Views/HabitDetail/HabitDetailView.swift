import SwiftUI

// MARK: - HabitOptionsMenu
struct HabitOptionsMenu: View {
    let onChangeValue: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onReset: () -> Void
    
    var body: some View {
        Menu {
            Button(action: onChangeValue) {
                Text("Change value")
            }
            
            Button(action: onEdit) {
                Text("Edit")
            }
            
            Button(action: onReset) {
                Text("Reset")
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
    
    let onEdit: (Habit) -> Void
    let onDelete: (Habit) -> Void
    let onUpdate: ((Habit, Double) -> Void)?
    let onComplete: ((Habit) -> Void)?
    
    init(
        habit: Habit,
        habitStore: HabitStoreManager,
        onEdit: @escaping (Habit) -> Void,
        onDelete: @escaping (Habit) -> Void,
        onUpdate: ((Habit, Double) -> Void)? = nil,
        onComplete: ((Habit) -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: HabitDetailViewModel(habit: habit, habitStore: habitStore))
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onUpdate = onUpdate
        self.onComplete = onComplete
        
        viewModel.onUpdate = { value in
            onUpdate?(habit, value)
        }
        
        viewModel.onComplete = {
            onComplete?(habit)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ProgressCircleView(
                        progress: viewModel.progress,
                        goal: viewModel.habit.goal,
                        type: viewModel.habit.type,
                        isCompleted: viewModel.isCompleted,
                        currentValue: viewModel.currentValue
                    )
                    .padding(.top, 20)
                    
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
                }
                .padding()
            }
            .navigationTitle(viewModel.habit.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HabitOptionsMenu(
                        onChangeValue: { viewModel.showManualInputPanel() },
                        onEdit: { onEdit(viewModel.habit) },
                        onDelete: { onDelete(viewModel.habit) },
                        onReset: { viewModel.reset() }
                    )
                }
            }
            .sheet(isPresented: $viewModel.showManualInput) {
                ManualInputPanelView(
                    type: viewModel.habit.type,
                    isPresented: $viewModel.showManualInput,
                    initialValue: viewModel.currentValue,
                    isAddMode: viewModel.isAddMode,
                    onSubmit: { value in
                        viewModel.setValue(value)
                    }
                )
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
