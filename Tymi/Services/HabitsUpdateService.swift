import SwiftUI

@Observable
final class HabitsUpdateService {
    var lastUpdateTimestamp: Date = Date()
    private var updateTask: Task<Void, Never>?
    
    func triggerDelayedUpdate(delay: TimeInterval = 0.5) {
        // Отменяем предыдущую задачу
        updateTask?.cancel()
        
        // Создаем новую задачу с задержкой
        updateTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(delay))
                if !Task.isCancelled {
                    self.lastUpdateTimestamp = Date()
                }
            } catch {
                // Игнорируем ошибки отмены
            }
        }
    }
    
    func triggerUpdate() {
        lastUpdateTimestamp = Date()
    }
}
