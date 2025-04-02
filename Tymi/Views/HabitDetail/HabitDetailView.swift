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
        ZStack {
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
                    
                    HStack(spacing: 12) {
                        Button {
                            viewModel.showOptions = true
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.body.weight(.medium))
                        }
                        .buttonStyle(GlassButtonStyle(size: 44))
                        
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                isPresented = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.medium))
                        }
                        .buttonStyle(GlassButtonStyle(size: 44))
                    }
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
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .systemBackground).opacity(0.01))
            
            if viewModel.showManualInput {
                if viewModel.habit.type == .time {
                    TimePickerView(
                        isPresented: $viewModel.showManualInput,
                        onSave: viewModel.setValue
                    )
                } else {
                    // Number input for .count
                    VStack {
                        TextField("Value", value: .init(
                            get: { viewModel.currentValue },
                            set: { viewModel.setValue($0) }
                        ), format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                        
                        HStack {
                            Button("Cancel") {
                                viewModel.showManualInput = false
                            }
                            
                            Button("Done") {
                                viewModel.showManualInput = false
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .systemBackground).opacity(0.8))
                            .background(.ultraThinMaterial)
                    )
                    .frame(maxWidth: 300)
                }
            }
            
            if viewModel.showOptions {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            viewModel.showOptions = false
                        }
                    
                    VStack(spacing: 16) {
                        Button {
                            viewModel.showOptions = false
                            onEdit?(viewModel.habit)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassButtonStyle())
                        
                        Button(role: .destructive) {
                            viewModel.showOptions = false
                            onDelete?(viewModel.habit)
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassButtonStyle())
                        
                        Button(role: .destructive) {
                            viewModel.showOptions = false
                            viewModel.reset()
                        } label: {
                            Label("Reset Progress", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .systemBackground).opacity(0.8))
                            .background(.ultraThinMaterial)
                    )
                    .frame(maxWidth: 300)
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                viewModel.resumeTimerIfNeeded()
            case .inactive, .background:
                viewModel.pauseTimerIfNeeded()
            @unknown default:
                break
            }
        }
    }
    
    private var goalText: String {
        switch viewModel.habit.type {
        case .time:
            let hours = Int(viewModel.habit.goal) / 60
            let minutes = Int(viewModel.habit.goal) % 60
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        case .count:
            return "\(Int(viewModel.habit.goal))"
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
