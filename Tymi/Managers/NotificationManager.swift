import Foundation
import UserNotifications
import SwiftUI
import SwiftData

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var permissionStatus: Bool = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    
    private init() {
        Task {
            permissionStatus = await checkNotificationStatus()
        }
    }
    
    // Запрос разрешений на уведомления (требует async/await)
    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        
        await MainActor.run {
            self.permissionStatus = granted
        }
        
        return granted
    }
    
    // Планирование уведомлений для привычки с проверкой разрешений
    func scheduleNotifications(for habit: Habit) async -> Bool {
        // Проверяем, есть ли у нас разрешение на уведомления
        guard notificationsEnabled else {
            cancelNotifications(for: habit)
            return false
        }
        
        // Проверяем статус разрешений
        let isAuthorized = await checkNotificationStatus()
        if !isAuthorized {
            return false
        }
        
        // Проверяем наличие времени напоминания
        guard let reminderTime = habit.reminderTime else {
            cancelNotifications(for: habit)
            return false
        }
        
        // Сначала отменяем старые уведомления
        cancelNotifications(for: habit)
        
        let calendar = Calendar.userPreferred
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        // Создаем уведомления для каждого активного дня недели
        for (index, isActive) in habit.activeDays.enumerated() where isActive {
            let weekday = calendar.systemWeekdayFromOrdered(index: index)
            
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
                identifier: "\(habit.uuid.uuidString)-\(weekday)",
                content: content,
                trigger: trigger
            )
            
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                print("Ошибка при планировании уведомления: \(error.localizedDescription)")
                return false
            }
        }
        
        return true
    }
    
    // Отмена уведомлений для привычки
    func cancelNotifications(for habit: Habit) {
        let identifiers = (1...7).map { weekday in
            "\(habit.uuid.uuidString)-\(weekday)"
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    // Упрощенное обновление в updateAllNotifications
    func updateAllNotifications(modelContext: ModelContext) {
        // Удаляем все запланированные уведомления
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Проверяем, включены ли уведомления в приложении
        guard notificationsEnabled else {
            return
        }
        
        // Асинхронно проверяем разрешения
        Task {
            let isAuthorized = await checkNotificationStatus()
            
            if !isAuthorized {
                // Если разрешения отсутствуют, обновляем состояние приложения
                await MainActor.run {
                    notificationsEnabled = false
                }
                return
            }
            
            // Продолжаем только если есть разрешение
            let descriptor = FetchDescriptor<Habit>()
            do {
                let habits = try modelContext.fetch(descriptor)
                // Планируем уведомления только для привычек с настроенным временем напоминания
                for habit in habits where habit.reminderTime != nil {
                    _ = await scheduleNotifications(for: habit)
                }
            } catch {
                print("Ошибка при обновлении уведомлений: \(error)")
            }
        }
    }
    
    // Проверка статуса разрешений на уведомления
    func checkNotificationStatus() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    // Проверка и обработка отключенных уведомлений
    func handleDisabledNotifications() async {
        // Предотвращаем лишние обновления UI
        let isCurrentlyEnabled = notificationsEnabled
        let isAuthorized = await checkNotificationStatus()
        
        if !isAuthorized && isCurrentlyEnabled {
            await MainActor.run {
                notificationsEnabled = false
            }
        }
    }
}
