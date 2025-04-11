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
                    
                    HStack(spacing: 16) {
                        Button {
                            viewModel.undo()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 20, weight: .medium))
                        }
                        .buttonStyle(GlassButtonStyle())
                        .disabled(!viewModel.canUndo)
                        
                        Button {
                            viewModel.decrement()
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 20, weight: .medium))
                        }
                        .buttonStyle(GlassButtonStyle())
                        
                        Button {
                            viewModel.increment()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                        }
                        .buttonStyle(GlassButtonStyle())
                        
                        Button {
                            withAnimation {
                                viewModel.isExpanded.toggle()
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .medium))
                                .rotationEffect(.degrees(viewModel.isExpanded ? 90 : 0))
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    if viewModel.isExpanded {
                        VStack(spacing: 16) {
                            if viewModel.habit.type == .time {
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
                                .padding(.horizontal)
                            }
                            
                            ExpandedControls(
                                onDecrementLarge: { viewModel.decrement(by: 30) },
                                onDecrementSmall: { viewModel.decrement(by: 10) },
                                onIncrementSmall: { viewModel.increment(by: 10) },
                                onIncrementLarge: { viewModel.increment(by: 30) },
                                onManualInput: { viewModel.showManualInputPanel(isAdd: true) }
                            )
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                    
                    Button {
                        viewModel.setValue(viewModel.habit.goal)
                    } label: {
                        Text("Complete")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                Color(.label)
                                    .clipShape(RoundedRectangle(cornerRadius: 28))
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .navigationTitle(viewModel.habit.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HabitOptionsMenu(
                        onChangeValue: { viewModel.showManualInputPanel(isAdd: false) },
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
                    initialValue: nil,
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
