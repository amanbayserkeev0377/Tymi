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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @Binding var isPresented: Bool
    @State private var showDeleteConfirmation = false
    
    var onEdit: ((Habit) -> Void)?
    var onDelete: ((Habit) -> Void)?
    var onUpdate: ((Habit, Double) -> Void)?
    var onComplete: ((Habit) -> Void)?
    
    init(
        habit: Habit,
        habitStore: HabitStoreManager,
        isPresented: Binding<Bool>,
        onEdit: ((Habit) -> Void)? = nil,
        onDelete: ((Habit) -> Void)? = nil,
        onUpdate: ((Habit, Double) -> Void)? = nil,
        onComplete: ((Habit) -> Void)? = nil
    ) {
        _isPresented = isPresented
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
        NavigationView {
            ZStack {
                if viewModel.showManualInput {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.showManualInput = false
                            }
                        }
                }
                
                VStack(spacing: 0) {
                    VStack(spacing: 32) {
                        // Options Menu
                        HStack {
                            Text(goalText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            HabitOptionsMenu(
                                onChangeValue: { viewModel.showManualInputPanel(isAdd: false) },
                                onEdit: { onEdit?(viewModel.habit) },
                                onDelete: { showDeleteConfirmation = true }
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Progress Circle
                        ProgressCircleView(
                            progress: viewModel.progress,
                            goal: viewModel.habit.goal,
                            type: viewModel.habit.type,
                            isCompleted: viewModel.isCompleted,
                            currentValue: viewModel.currentValue
                        )
                        .padding(.vertical, 16)
                        
                        // Action Buttons Row
                        HStack(spacing: 16) {
                            if viewModel.habit.type == .count {
                                Button {
                                    viewModel.decrement()
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                        .frame(width: 44, height: 44)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                                
                                Button {
                                    viewModel.increment()
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                        .frame(width: 44, height: 44)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                            } else {
                                Button {
                                    viewModel.toggleTimer()
                                } label: {
                                    Image(systemName: viewModel.isPlaying ? "pause" : "play")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                        .frame(width: 44, height: 44)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                            }
                            
                            Button {
                                viewModel.showManualInputPanel(isAdd: true)
                            } label: {
                                Image(systemName: "plus.forwardslash.minus")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            
                            Button {
                                viewModel.reset()
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            
                            if viewModel.canUndo {
                                Button {
                                    viewModel.undo()
                                } label: {
                                    Image(systemName: "arrow.uturn.backward")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                        .frame(width: 44, height: 44)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.vertical, 24)
                }
                
                if viewModel.showManualInput {
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
            .navigationTitle(viewModel.habit.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                switch newPhase {
                case .active:
                    viewModel.onAppear()
                case .inactive, .background:
                    viewModel.onDisappear()
                @unknown default:
                    break
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
        }
    }
    
    private var goalText: String {
        switch viewModel.habit.type {
        case .count:
            return "\(Int(viewModel.habit.goal)) times"
        case .time:
            let hours = Int(viewModel.habit.goal) / 3600
            let minutes = Int(viewModel.habit.goal) / 60 % 60
            return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
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
