import Foundation
import Combine

protocol HabitTimerManaging: AnyObject {
    var onValueUpdate: ((ValueType) -> Void)? { get set }
    var isPlaying: Bool { get }
    var startTime: Date? { get }
    
    func start()
    func pause()
    func resumeIfNeeded()
    func pauseIfNeeded()
    func cleanup()
} 