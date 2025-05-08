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
    
    // Запрос разрешений на уведомления
    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        permissionStatus = await checkNotificationStatus()
    }
    
    // Планирование уведомлений для привычки
    func scheduleNotifications(for habit: Habit) {
        // Если уведомления отключены или нет времени напоминания - отменяем уведомления
        guard notificationsEnabled, let reminderTime = habit.reminderTime else {
            cancelNotifications(for: habit)
            return
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
                identifier: "\(habit.id)-\(weekday)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Отмена уведомлений для привычки
    func cancelNotifications(for habit: Habit) {
        let identifiers = (1...7).map { weekday in
            "\(habit.id)-\(weekday)"
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    // Обновление всех уведомлений
    func updateAllNotifications(modelContext: ModelContext) {
        // Удаляем все запланированные уведомления
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Если уведомления отключены, просто выходим
        if !notificationsEnabled {
            return
        }
        
        // Запрашиваем все привычки
        let descriptor = FetchDescriptor<Habit>()
        do {
            let habits = try modelContext.fetch(descriptor)
            // Планируем уведомления только для привычек с настроенным временем напоминания
            for habit in habits where habit.reminderTime != nil {
                scheduleNotifications(for: habit)
            }
        } catch {
            print("Error when updating notifications: \(error)")
        }
    }
    
    // Проверка статуса разрешений на уведомления
    func checkNotificationStatus() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
}
