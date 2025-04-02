import SwiftUI

struct HabitDetailView: View {
    @StateObject private var viewModel: HabitDetailViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @Binding var isPresented: Bool
    
    var onEdit: ((Habit) -> Void)?
    var onDelete: ((Habit) -> Void)?
    var onUpdate: ((Habit, Double) -> Void)?
    var onComplete: ((Habit) -> Void)?
    
    init(
        habit: Habit,
        isPresented: Binding<Bool>,
        onEdit: ((Habit) -> Void)? = nil,
        onDelete: ((Habit) -> Void)? = nil,
        onUpdate: ((Habit, Double) -> Void)? = nil,
        onComplete: ((Habit) -> Void)? = nil
    ) {
        let vm = HabitDetailViewModel(habit: habit)
        _viewModel = StateObject(wrappedValue: vm)
        _isPresented = isPresented
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onUpdate = onUpdate
        self.onComplete = onComplete
        
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
        VStack(spacing: 32) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.habit.name)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Text(goalText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    viewModel.showOptions = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body.weight(.medium))
                }
                .buttonStyle(GlassButtonStyle(size: 44))
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
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
            VStack(spacing: 24) {
                HStack(spacing: 16) {
                    // Undo Button
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.undo()
                        }
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.title3.weight(.medium))
                    }
                    .buttonStyle(GlassButtonStyle())
                    .disabled(!viewModel.canUndo)
                    
                    // Decrement Button
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.decrement()
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.title3.weight(.medium))
                    }
                    .buttonStyle(GlassButtonStyle())
                    
                    // Increment Button
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.increment()
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3.weight(.medium))
                    }
                    .buttonStyle(GlassButtonStyle())
                    
                    // Expand Button
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: viewModel.isExpanded ? "chevron.up" : "chevron.down")
                            .font(.title3.weight(.medium))
                    }
                    .buttonStyle(GlassButtonStyle())
                }
                .padding(.horizontal, 24)
                
                // Expanded Controls
                if viewModel.isExpanded {
                    HStack(spacing: 16) {
                        Button(action: { viewModel.decrement(by: 30) }) {
                            Text("-30")
                                .font(.title3.weight(.medium))
                        }
                        .buttonStyle(GlassButtonStyle())
                        
                        Button(action: { viewModel.decrement(by: 10) }) {
                            Text("-10")
                                .font(.title3.weight(.medium))
                        }
                        .buttonStyle(GlassButtonStyle())
                        
                        Button(action: { viewModel.showManualInput = true }) {
                            Image(systemName: "number")
                                .font(.title3.weight(.medium))
                        }
                        .buttonStyle(GlassButtonStyle())
                        
                        Button(action: { viewModel.increment(by: 10) }) {
                            Text("+10")
                                .font(.title3.weight(.medium))
                        }
                        .buttonStyle(GlassButtonStyle())
                        
                        Button(action: { viewModel.increment(by: 30) }) {
                            Text("+30")
                                .font(.title3.weight(.medium))
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            Spacer()
            
            // Bottom Action Button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    viewModel.toggleTimer()
                }
            } label: {
                HStack {
                    if viewModel.habit.type == .time {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3.weight(.semibold))
                    } else {
                        Text("Complete")
                            .font(.title3.weight(.semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .background(.black)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .modalStyle(isPresented: $isPresented)
        .confirmationDialog(
            "Options",
            isPresented: $viewModel.showOptions,
            titleVisibility: .hidden
        ) {
            Button("Edit") {
                onEdit?(viewModel.habit)
            }
            
            Button("Delete", role: .destructive) {
                onDelete?(viewModel.habit)
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                viewModel.onAppear()
            case .inactive, .background:
                viewModel.onDisappear()
            @unknown default:
                break
            }
        }
    }
    
    private var goalText: String {
        switch viewModel.habit.type {
        case .count:
            return "\(Int(viewModel.habit.goal)) times"
        case .time:
            return "\(Int(viewModel.habit.goal / 60)) minutes"
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
                    Image(systemName: "number")
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
