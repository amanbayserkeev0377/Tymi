import Foundation
import UserNotifications
import SwiftUI
import SwiftData

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var permissionStatus: Bool = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("firstDayOfWeek") private var firstDayOfWeek: Int = 0
    
    private init() {
        setupNotifications()
        Task {
            permissionStatus = await checkNotificationStatus()
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFirstDayOfWeekChanged),
            name: NSNotification.Name("FirstDayOfWeekChanged"),
            object: nil
        )
    }
    
    @objc private func handleFirstDayOfWeekChanged(_ notification: Notification) {
        if let firstDayOfWeek = notification.userInfo?["firstDayOfWeek"] as? Int {
            updateAllNotifications(firstDayOfWeek: firstDayOfWeek)
        }
    }
    
    private func updateAllNotifications(firstDayOfWeek: Int) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            guard let self = self else { return }
            
            for request in requests {
                self.updateNotification(request, firstDayOfWeek: firstDayOfWeek)
            }
        }
    }
    
    private func updateNotification(_ request: UNNotificationRequest, firstDayOfWeek: Int) {
        guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
              let weekday = trigger.dateComponents.weekday else {
            return
        }
        
        // Отменяем старое уведомление
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
        
        // Создаем новое уведомление с обновленным днем недели
        var newDateComponents = trigger.dateComponents
        newDateComponents.weekday = weekday
        
        let newTrigger = UNCalendarNotificationTrigger(dateMatching: newDateComponents, repeats: true)
        let newRequest = UNNotificationRequest(
            identifier: request.identifier,
            content: request.content,
            trigger: newTrigger
        )
        
        UNUserNotificationCenter.current().add(newRequest)
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
        
        cancelNotifications(for: habit)
        
        let calendar = Calendar.userPreferred
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
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
    
    func cancelNotifications(for habit: Habit) {
        // Удалена неиспользуемая переменная calendar
        
        let identifiers = (1...7).map { weekday in
            "\(habit.id)-\(weekday)"
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    func updateAllNotifications(modelContext: ModelContext) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        if !notificationsEnabled {
            return
        }
        
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
