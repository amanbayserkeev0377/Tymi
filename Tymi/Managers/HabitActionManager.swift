import Foundation
import Combine
import UIKit

final class HabitActionManager: HabitActionManaging {
    private let habit: Habit
    private let dataStore: HabitDataStore
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private var lastAction: ProgressAction?
    private var totalAddedAmount: Double = 0
    private var undoneAmount: Double = 0
    private let maxUndoTimeInterval: TimeInterval = 300 // 5 minutes
    
    private(set) var currentValue: ValueType
    private(set) var canUndo: Bool = false
    
    var onValueUpdate: ((ValueType) -> Void)?
    var onCompletion: (() -> Void)?
    
    init(habit: Habit, dataStore: HabitDataStore = UserDefaultsService.shared) {
        self.habit = habit
        self.dataStore = dataStore
        self.currentValue = habit.type == .count ? .count(0) : .time(0)
        
        feedbackGenerator.prepare()
        notificationGenerator.prepare()
        
        loadState()
    }
    
    func increment(by amount: Double) {
        guard amount > 0 else { return }
        
        let oldValue = currentValue
        let increment = habit.type == .time ? amount * 60 : amount
        
        let newDoubleValue = currentValue.doubleValue + increment
        guard !newDoubleValue.isInfinite && !newDoubleValue.isNaN else { return }
        
        currentValue = ValueType.fromDouble(newDoubleValue, type: habit.type)
        
        let action = ProgressAction(
            oldValue: oldValue,
            newValue: currentValue,
            type: .increment(amount: amount),
            timestamp: Date(),
            addedAmount: increment
        )
        saveAction(action)
        
        feedbackGenerator.impactOccurred()
        updateProgress()
        saveState()
    }
    
    func decrement(by amount: Double) {
        guard amount > 0 else { return }
        
        let decrement = habit.type == .time ? amount * 60 : amount
        let oldValue = currentValue
        let newDoubleValue = max(0, currentValue.doubleValue - decrement)
        currentValue = ValueType.fromDouble(newDoubleValue, type: habit.type)
        
        if oldValue.doubleValue != currentValue.doubleValue {
            feedbackGenerator.impactOccurred()
        }
        
        updateProgress()
        saveState()
    }
    
    func setValue(_ value: Double, isAddMode: Bool) {
        guard !value.isInfinite && !value.isNaN && value >= 0 else { return }
        
        let oldValue = currentValue
        if isAddMode {
            let newDoubleValue = currentValue.doubleValue + value
            currentValue = ValueType.fromDouble(newDoubleValue, type: habit.type)
        } else {
            currentValue = ValueType.fromDouble(value, type: habit.type)
        }
        
        if oldValue.doubleValue != currentValue.doubleValue {
            feedbackGenerator.impactOccurred()
        }
        
        let addedAmount = isAddMode ? value : value - oldValue.doubleValue
        let action = ProgressAction(
            oldValue: oldValue,
            newValue: currentValue,
            type: .manualInput,
            timestamp: Date(),
            addedAmount: addedAmount
        )
        saveAction(action)
        
        updateProgress()
        saveState()
    }
    
    func reset() {
        let oldValue = currentValue
        currentValue = habit.type == .count ? .count(0) : .time(0)
        
        if oldValue.doubleValue != 0 {
            notificationGenerator.notificationOccurred(.warning)
        }
        
        let action = ProgressAction(
            oldValue: oldValue,
            newValue: currentValue,
            type: .reset,
            timestamp: Date(),
            addedAmount: nil as Double?
        )
        saveAction(action)
        
        updateProgress()
        saveState()
    }
    
    func undo() {
        guard let action = lastAction,
              Date().timeIntervalSince(action.timestamp) <= maxUndoTimeInterval,
              let actionAmount = action.addedAmount,
              actionAmount > 0,
              currentValue.doubleValue > 0
        else {
            canUndo = false
            return
        }
        
        let amountToSubtract: Double
        
        if case .increment(let incAmount) = action.type, incAmount == 1, totalAddedAmount > 1 {
            amountToSubtract = totalAddedAmount
            canUndo = false
            lastAction = nil
            totalAddedAmount = 0
            undoneAmount = 0
        } else {
            amountToSubtract = min(actionAmount, currentValue.doubleValue)
            undoneAmount += 1
            
            if currentValue.doubleValue <= amountToSubtract {
                canUndo = false
                lastAction = nil
                totalAddedAmount = 0
                undoneAmount = 0
            }
        }
        
        let newDoubleValue = max(0, currentValue.doubleValue - amountToSubtract)
        currentValue = ValueType.fromDouble(newDoubleValue, type: habit.type)
        
        feedbackGenerator.impactOccurred()
        updateProgress()
        saveState()
    }
    
    func saveState() {
        let state = HabitState(
            habitId: habit.id,
            currentValue: currentValue,
            isCompleted: currentValue.doubleValue >= habit.goal.doubleValue,
            lastUpdate: Date(),
            isPlaying: false,
            startTime: nil as Date?,
            habitType: habit.type,
            lastActionTimestamp: lastAction?.timestamp,
            lastActionType: lastAction?.type,
            lastActionAmount: lastAction?.addedAmount,
            totalAddedAmount: totalAddedAmount,
            undoneAmount: undoneAmount
        )
        
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: "habit_state_\(habit.id.uuidString)")
        }
    }
    
    func loadState() {
        guard let data = UserDefaults.standard.data(forKey: "habit_state_\(habit.id.uuidString)"),
              let state = try? JSONDecoder().decode(HabitState.self, from: data)
        else { return }
        
        currentValue = state.currentValue
        lastAction = state.lastActionType.map { type in
            ProgressAction(
                oldValue: currentValue,
                newValue: currentValue,
                type: type,
                timestamp: state.lastActionTimestamp ?? Date(),
                addedAmount: state.lastActionAmount
            )
        }
        totalAddedAmount = state.totalAddedAmount
        undoneAmount = state.undoneAmount
        
        updateProgress()
    }
    
    private func updateProgress() {
        let isCompleted = currentValue.doubleValue >= habit.goal.doubleValue
        if isCompleted {
            notificationGenerator.notificationOccurred(.success)
            onCompletion?()
        }
        
        onValueUpdate?(currentValue)
    }
    
    private func saveAction(_ action: ProgressAction) {
        lastAction = action
        
        if let amount = action.addedAmount, amount > 0 {
            if case .increment(let incAmount) = action.type, incAmount == 1 {
                totalAddedAmount += amount
            } else {
                totalAddedAmount = amount
            }
            undoneAmount = 0
        }
        canUndo = true
    }
} 