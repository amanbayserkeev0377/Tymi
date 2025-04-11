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
                .frame(width: 40, height: 40)
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
    @Environment(\.dismiss) private var dismiss
    
    @State private var isUndoPressed: Bool = false
    @State private var isDecrementPressed: Bool = false
    @State private var isTimerPressed: Bool = false
    @State private var isIncrementPressed: Bool = false
    @State private var dynamicButtonPressed: [String: Bool] = [:]
    
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
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : .white
    }
    
    private var strokeColor: Color {
        colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray5)
    }
    
    private var availableButtons: [DynamicButton] {
        let goalValue = viewModel.habit.goal.doubleValue
        var buttons: [DynamicButton] = []
        
        if viewModel.habit.type == .count {
            if goalValue >= 10 {
                buttons.append(.init(label: "+5", amount: 5))
            }
            if goalValue >= 50 {
                buttons.append(.init(label: "+10", amount: 10))
            }
            if goalValue >= 200 {
                buttons.append(.init(label: "+100", amount: 100))
            }
            if goalValue >= 2000 {
                buttons.append(.init(label: "+1k", amount: 1000))
            }
        } else {
            if goalValue >= 600 { // 10 минут
                buttons.append(.init(label: "+5m", amount: 5 * 60))
            }
            if goalValue >= 3600 { // 1 час
                buttons.append(.init(label: "+30m", amount: 30 * 60))
            }
            if goalValue >= 7200 { // 2 часа
                buttons.append(.init(label: "+60m", amount: 60 * 60))
            }
        }
        return buttons
    }
    
    private struct DynamicButton {
        let label: String
        let amount: Double
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(viewModel.habit.name)
                    .font(.headline)
                
                Spacer()
                
                Button {
                    viewModel.showOptions = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Progress Circle
                    ProgressCircleView(
                        progress: viewModel.progress,
                        goal: viewModel.habit.goal,
                        type: viewModel.habit.type,
                        isCompleted: viewModel.isCompleted,
                        currentValue: viewModel.currentValue
                    )
                    .frame(height: 200)
                    
                    // Controls
                    HStack(spacing: 16) {
                        Button {
                            viewModel.undo()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 20, weight: .medium))
                        }
                        .buttonStyle(GlassButtonStyle())
                        .disabled(!viewModel.canUndo)
                        .scaleEffect(isUndoPressed ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isUndoPressed)
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in isUndoPressed = true }
                                .onEnded { _ in isUndoPressed = false }
                        )
                        
                        Button {
                            viewModel.decrement()
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 20, weight: .medium))
                        }
                        .buttonStyle(GlassButtonStyle())
                        .scaleEffect(isDecrementPressed ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isDecrementPressed)
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in isDecrementPressed = true }
                                .onEnded { _ in isDecrementPressed = false }
                        )
                        
                        if viewModel.habit.type == .time {
                            Button {
                                viewModel.toggleTimer()
                            } label: {
                                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(viewModel.isPlaying ? .red : .green)
                            }
                            .buttonStyle(GlassButtonStyle())
                            .scaleEffect(isTimerPressed ? 0.95 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isTimerPressed)
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in isTimerPressed = true }
                                    .onEnded { _ in isTimerPressed = false }
                            )
                        }
                        
                        Button {
                            viewModel.increment()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                        }
                        .buttonStyle(GlassButtonStyle())
                        .scaleEffect(isIncrementPressed ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isIncrementPressed)
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in isIncrementPressed = true }
                                .onEnded { _ in isIncrementPressed = false }
                        )
                        
                        ForEach(availableButtons, id: \.label) { button in
                            Button {
                                viewModel.increment(by: button.amount)
                            } label: {
                                Text(button.label)
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .buttonStyle(GlassButtonStyle())
                            .scaleEffect(dynamicButtonPressed[button.label] ?? false ? 0.95 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: dynamicButtonPressed[button.label])
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in dynamicButtonPressed[button.label] = true }
                                    .onEnded { _ in dynamicButtonPressed[button.label] = false }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Manual Input Button
                    Button {
                        viewModel.showManualInputPanel()
                    } label: {
                        Text("Manual Input")
                            .font(.body.weight(.medium))
                            .foregroundStyle(colorScheme == .light ? .white : .black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                (colorScheme == .light ? Color.black : Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
        }
        .background(backgroundColor)
        .onAppear {
            viewModel.onUpdate = { value in
                onUpdate?(viewModel.habit, value)
            }
            
            viewModel.onComplete = {
                onComplete?(viewModel.habit)
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
        .sheet(isPresented: $viewModel.showOptions) {
            HabitOptionsMenu(
                onChangeValue: { viewModel.showManualInputPanel(isAdd: false) },
                onEdit: { onEdit(viewModel.habit) },
                onDelete: { onDelete(viewModel.habit) },
                onReset: { viewModel.reset() }
            )
        }
    }
}

#Preview {
    HabitDetailView(
        habit: Habit(name: "Getting Started"),
        habitStore: HabitStoreManager(),
        onEdit: { _ in },
        onDelete: { _ in }
    )
}
