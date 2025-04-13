import Foundation
import Combine

protocol HabitActionManaging: AnyObject {
    var canUndo: Bool { get }
    var currentValue: ValueType { get }
    var onValueUpdate: ((ValueType) -> Void)? { get set }
    var onCompletion: (() -> Void)? { get set }
    
    func increment(by amount: Double)
    func decrement(by amount: Double)
    func setValue(_ value: Double, isAddMode: Bool)
    func reset()
    func undo()
    
    func saveState()
    func loadState()
} 