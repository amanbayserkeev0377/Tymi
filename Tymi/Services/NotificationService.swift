import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()
    
    private init() {}
    
    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Ошибка запроса разрешений: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotifications(for habit: Habit) {
        // Сначала отменяем все существующие уведомления для этой привычки
        cancelNotifications(for: habit)
        
        // Создаем уведомления только для активных напоминаний
        let activeReminders = habit.reminders.filter { $0.isEnabled }
        
        for reminder in activeReminders {
            // Для каждого дня недели в reminder.days создаем отдельное уведомление
            for day in reminder.days {
                let content = UNMutableNotificationContent()
                content.title = "Время для привычки"
                content.body = "Не забудьте: \(habit.name)"
                content.sound = .default
                
                // Получаем компоненты времени из reminder.time
                let calendar = Calendar.current
                var components = calendar.dateComponents([.hour, .minute], from: reminder.time)
                components.weekday = day // 1 = Sunday, 7 = Saturday в UNCalendar
                
                // Создаем триггер для повторения каждую неделю в указанный день и время
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                
                // Создаем уникальный идентификатор для каждого уведомления
                let identifier = "\(habit.id)-\(reminder.id)-\(day)"
                
                let request = UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )
                
                center.add(request) { error in
                    if let error = error {
                        print("Ошибка планирования уведомления: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func cancelNotifications(for habit: Habit) {
        // Получаем все идентификаторы уведомлений для данной привычки
        center.getPendingNotificationRequests { requests in
            let identifiers = requests
                .filter { $0.identifier.starts(with: habit.id.uuidString) }
                .map { $0.identifier }
            
            self.center.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
} 