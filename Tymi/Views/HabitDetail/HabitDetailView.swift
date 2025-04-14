import SwiftUI

// MARK: - HabitOptionsMenu
struct HabitOptionsMenu: View {
    @Environment(\.colorScheme) private var colorScheme
    
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
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .frame(width: 23, height: 23)
                .overlay(
                    Circle()
                        .stroke(colorScheme == .dark ? .white : .black, lineWidth: 1)
                )
                .contentShape(Circle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
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
    @State private var showingDeleteAlert: Bool = false
    
    let onEdit: (Habit) -> Void
    let onDelete: (Habit) -> Void
    let onUpdate: ((Habit, Double) -> Void)?
    let onComplete: ((Habit) -> Void)?
    
    init(
        habit: Habit,
        onEdit: @escaping (Habit) -> Void,
        onDelete: @escaping (Habit) -> Void,
        onUpdate: ((Habit, Double) -> Void)? = nil,
        onComplete: ((Habit) -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: HabitDetailViewModel(habit: habit))
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
                buttons.append(.init(label: "+5", amount: 5))
            }
            if goalValue >= 3600 { // 1 час
                buttons.append(.init(label: "+30", amount: 30))
            }
            if goalValue >= 7200 { // 2 часа
                buttons.append(.init(label: "+60", amount: 60))
            }
        }
        return buttons
    }
    
    private struct DynamicButton {
        let label: String
        let amount: Double
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Progress Circle with side buttons
                HStack(spacing: 16) {
                    // Minus button
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
                    
                    // Progress Circle
                    ProgressCircleView(
                        progress: viewModel.progress,
                        goal: viewModel.habit.goal,
                        type: viewModel.habit.type,
                        isCompleted: viewModel.isCompleted,
                        currentValue: viewModel.currentValue
                    )
                    .frame(height: 200)
                    
                    // Plus button
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
                }
                .padding(.horizontal)
                
                // Statistics
                HStack(spacing: 20) {
                    // Current Streak
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Text("🔥")
                                .font(.system(size: 16))
                            Text("Streak:")
                                .font(.system(size: 14, weight: .medium))
                        }
                        Text("\(viewModel.currentStreak)")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Best Streak
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Text("🏆")
                                .font(.system(size: 16))
                            Text("Best:")
                                .font(.system(size: 14, weight: .medium))
                        }
                        Text("\(viewModel.bestStreak)")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Completed Count
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Text("✔")
                                .font(.system(size: 16))
                            Text("Completed:")
                                .font(.system(size: 14, weight: .medium))
                        }
                        Text("\(viewModel.completedCount)")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                
                // Main Controls
                HStack(spacing: 16) {
                    Button {
                        viewModel.undo()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 20, weight: .medium))
                    }
                    .buttonStyle(GlassButtonStyle())
                    .disabled(!viewModel.canUndo)
                    .opacity(viewModel.canUndo ? 1.0 : 0.5)
                    .scaleEffect(isUndoPressed ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isUndoPressed)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in isUndoPressed = true }
                            .onEnded { _ in isUndoPressed = false }
                    )
                    
                    // Manual Input Button
                    Button {
                        viewModel.showManualInputPanel()
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 20, weight: .medium))
                    }
                    .buttonStyle(GlassButtonStyle())
                    
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
                        .id(viewModel.isPlaying)
                    }
                }
                .padding(.horizontal)
                
                // Dynamic Buttons
                if !availableButtons.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableButtons, id: \.label) { button in
                                Button {
                                    viewModel.increment(by: button.amount)
                                } label: {
                                    Text(button.label)
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .buttonStyle(GlassButtonStyle())
                                .scaleEffect(dynamicButtonPressed[button.label] == true ? 0.95 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: dynamicButtonPressed[button.label])
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            dynamicButtonPressed[button.label] = true
                                        }
                                        .onEnded { _ in
                                            dynamicButtonPressed[button.label] = false
                                        }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Complete Button
                if !viewModel.isCompleted {
                    Button {
                        viewModel.setValue(viewModel.habit.goal.doubleValue)
                    } label: {
                        Text("Complete")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(backgroundColor)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(viewModel.habit.name)
                    .font(.system(size: 17, weight: .semibold))
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                HabitOptionsMenu(
                    onChangeValue: { viewModel.showManualInputPanel() },
                    onEdit: { onEdit(viewModel.habit) },
                    onDelete: { showingDeleteAlert = true },
                    onReset: { viewModel.reset() }
                )
            }
        }
        .alert("Delete Habit", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete(viewModel.habit)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this habit? This action cannot be undone.")
        }
        .sheet(isPresented: $viewModel.showManualInput) {
            ManualInputPanelView(
                type: viewModel.habit.type,
                isPresented: $viewModel.showManualInput,
                initialValue: nil,
                isAddMode: viewModel.isAddMode,
                onSubmit: { value in
                    viewModel.setValue(value)
                    viewModel.showManualInput = false
                }
            )
        }
        .onChange(of: viewModel.isCompleted) { _, isCompleted in
            if isCompleted {
                onComplete?(viewModel.habit)
            }
        }
        .onChange(of: viewModel.isPlaying) { _, newValue in
            print("isPlaying changed to: \(newValue)")
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
}

#Preview {
    NavigationStack {
        HabitDetailView(
            habit: Habit(name: "Getting Started"),
            onEdit: { _ in },
            onDelete: { _ in }
        )
    }
}
