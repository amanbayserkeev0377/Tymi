import Foundation
import UserNotifications
import SwiftUI
import SwiftData

@Observable
class NotificationManager {
    static let shared = NotificationManager()
    
    var permissionStatus: Bool = false
    
    var notificationsEnabled: Bool {
            get {
                return UserDefaults.standard.bool(forKey: "notificationsEnabled")
            }
            set {
                UserDefaults.standard.set(newValue, forKey: "notificationsEnabled")
            }
        }

    
    private init() {
        Task {
            permissionStatus = await checkNotificationStatus()
        }
    }
    
    // Единый метод для обеспечения разрешений
    func ensureAuthorization() async -> Bool {
        // Если уведомления отключены в приложении, просто возвращаем false
        guard notificationsEnabled else {
            return false
        }
        
        // Проверяем текущий статус
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if settings.authorizationStatus == .authorized {
            // Обновляем UI-статус на главном потоке
            await MainActor.run {
                permissionStatus = true
            }
            return true
        }
        
        // Если разрешения еще не запрашивались, запрашиваем
        if settings.authorizationStatus == .notDetermined {
            do {
                let options: UNAuthorizationOptions = [.alert, .sound, .badge]
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
                
                // Обновляем UI-статус на главном потоке
                await MainActor.run {
                    permissionStatus = granted
                }
                return granted
            } catch {
                print("Ошибка запроса разрешений: \(error)")
                await MainActor.run {
                    permissionStatus = false
                }
                return false
            }
        }
        
        // Для других статусов (denied, provisional, ...) возвращаем текущий статус
        return settings.authorizationStatus == .authorized
    }
    
    func scheduleNotifications(for habit: Habit) async -> Bool {
        // Проверяем, есть ли у нас разрешение на уведомления
        guard notificationsEnabled, await ensureAuthorization() else {
            cancelNotifications(for: habit)
            return false
        }
        
        // Проверяем наличие времен напоминаний
        guard let reminderTimes = habit.reminderTimes, !reminderTimes.isEmpty else {
            cancelNotifications(for: habit)
            return false
        }
        
        // Сначала отменяем старые уведомления
        cancelNotifications(for: habit)
        
        // Для каждого времени напоминания создаем уведомления по дням
        for (timeIndex, reminderTime) in reminderTimes.enumerated() {
            let calendar = Calendar.userPreferred
            let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
            
            // Создаем уведомления для каждого активного дня недели
            for (dayIndex, isActive) in habit.activeDays.enumerated() where isActive {
                let weekday = calendar.systemWeekdayFromOrdered(index: dayIndex)
                
                var dateComponents = DateComponents()
                dateComponents.hour = components.hour
                dateComponents.minute = components.minute
                dateComponents.weekday = weekday
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                
                let content = UNMutableNotificationContent()
                content.title = "habit_time".localized
                content.body = "dont_forget".localized(with: habit.title)
                content.sound = .default
                
                let request = UNNotificationRequest(
                    identifier: "\(habit.uuid.uuidString)-\(weekday)-\(timeIndex)",
                    content: content,
                    trigger: trigger
                )
                
                do {
                    try await UNUserNotificationCenter.current().add(request)
                } catch {
                    print("Ошибка при планировании уведомления: \(error.localizedDescription)")
                    // Продолжаем добавлять другие уведомления, если возможно
                }
            }
        }
        
        return true
    }

    func cancelNotifications(for habit: Habit) {
        // Получаем все возможные идентификаторы
        let identifiers: [String] = (0..<5).flatMap { timeIndex in
            (1...7).map { weekday in
                "\(habit.uuid.uuidString)-\(weekday)-\(timeIndex)"
            }
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    func updateAllNotifications(modelContext: ModelContext) {
        // Проверяем, включены ли уведомления в приложении
        guard notificationsEnabled else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            return
        }
        
        Task {
            // Проверяем разрешения
            let isAuthorized = await ensureAuthorization()
            
            if !isAuthorized {
                // Если разрешения отсутствуют, обновляем состояние приложения
                await MainActor.run {
                    notificationsEnabled = false
                }
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                return
            }
            
            // Получаем все привычки с напоминаниями
            let descriptor = FetchDescriptor<Habit>(predicate: #Predicate<Habit> { habit in
                habit.reminderTimes != nil
            })
            
            do {
                let habits = try modelContext.fetch(descriptor)
                // Планируем уведомления для каждой привычки
                for habit in habits {
                    _ = await scheduleNotifications(for: habit)
                }
            } catch {
                print("Ошибка при обновлении уведомлений: \(error)")
            }
        }
    }
    
    func checkNotificationStatus() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
}
