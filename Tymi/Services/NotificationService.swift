import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            }
        }
    }
    
    func scheduleNotification(for habit: Habit) {
        guard let reminderTime = habit.reminderTime else { return }
        
        // Удаляем старые уведомления для этой привычки
        cancelNotifications(for: habit)
        
        // Создаем компоненты времени для уведомления
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        // Создаем триггер для каждого активного дня
        for weekday in habit.activeDays {
            var triggerComponents = components
            triggerComponents.weekday = weekday
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)
            
            // Создаем контент уведомления
            let content = UNMutableNotificationContent()
            content.title = "Время для привычки"
            content.body = "Не забудьте выполнить: \(habit.name)"
            content.sound = .default
            
            // Создаем запрос на уведомление
            let request = UNNotificationRequest(
                identifier: "habit_\(habit.id.uuidString)_\(weekday)",
                content: content,
                trigger: trigger
            )
            
            // Добавляем уведомление
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }
    }
    
    func cancelNotifications(for habit: Habit) {
        let identifiers = habit.activeDays.map { "habit_\(habit.id.uuidString)_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
} 