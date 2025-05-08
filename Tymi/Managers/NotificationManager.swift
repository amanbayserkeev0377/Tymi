import Foundation
import UserNotifications
import SwiftUI
import SwiftData

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @StateObject private var calendarManager = CalendarManager.shared
    
    @Published var permissionStatus: Bool = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    
    private init() {
        setupNotifications()
        Task {
            permissionStatus = await checkNotificationStatus()
        }
    }
    
    private func setupNotifications() {
        // Регистрируем наблюдатель за изменением первого дня недели
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFirstDayOfWeekChanged),
            name: NSNotification.Name("FirstDayOfWeekChanged"),
            object: nil
        )
    }
    
    @objc private func handleFirstDayOfWeekChanged(_ notification: Notification) {
        if let firstDayOfWeek = notification.userInfo?["firstDayOfWeek"] as? Int {
            // Обновляем все уведомления с учетом нового первого дня недели
            updateAllNotifications(firstDayOfWeek: firstDayOfWeek)
        }
    }
    
    private func updateAllNotifications(firstDayOfWeek: Int) {
        // Получаем все активные уведомления
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            for request in requests {
                // Обновляем каждое уведомление с учетом нового первого дня недели
                self.updateNotification(request, firstDayOfWeek: firstDayOfWeek)
            }
        }
    }
    
    private func updateNotification(_ request: UNNotificationRequest, firstDayOfWeek: Int) {
        // Здесь логика обновления конкретного уведомления
        // Например, если уведомление привязано к определенному дню недели,
        // нужно пересчитать его с учетом нового первого дня недели
    }
    
    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        permissionStatus = await checkNotificationStatus()
    }
    
    func scheduleNotifications(for habit: Habit) {
        guard notificationsEnabled, let reminderTime = habit.reminderTime else {
            cancelNotifications(for: habit)
            return
        }
        
        // Отменяем существующие уведомления для этой привычки
        cancelNotifications(for: habit)
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        // Создаем уведомления для каждого активного дня
        for (index, isActive) in habit.activeDays.enumerated() where isActive {
            let weekday = Weekday.orderedByUserPreference[index]
            
            var dateComponents = DateComponents()
            dateComponents.hour = components.hour
            dateComponents.minute = components.minute
            dateComponents.weekday = weekday.rawValue + 1 // UNCalendarNotificationTrigger использует 1-7 для дней недели (1 = воскресенье)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let content = UNMutableNotificationContent()
            content.title = "habit_time".localized
            content.body = "dont_forget".localized(with: habit.title)
            content.sound = .default
            
            let request = UNNotificationRequest(
                identifier: "\(habit.id)-\(weekday.rawValue)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func cancelNotifications(for habit: Habit) {
        let identifiers = Weekday.orderedByUserPreference.map { "\(habit.id)-\($0.rawValue)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func updateAllNotifications(modelContext: ModelContext) {
        // Сначала удаляем все уведомления
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Если уведомления отключены глобально, выходим
        if !notificationsEnabled {
            return
        }
        
        // Получаем все привычки и перепланируем уведомления
        let descriptor = FetchDescriptor<Habit>()
        do {
            let habits = try modelContext.fetch(descriptor)
            for habit in habits where habit.reminderTime != nil {
                scheduleNotifications(for: habit)
            }
        } catch {
            print("Error when updating notifications: \(error)")
        }
    }
    
    func checkNotificationStatus() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
} 
