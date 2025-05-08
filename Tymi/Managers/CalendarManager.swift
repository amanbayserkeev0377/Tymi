import Foundation

class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    
    @Published private(set) var calendar: Calendar
    
    private init() {
        self.calendar = Calendar.current
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFirstDayOfWeekChanged),
            name: Notification.Name("FirstDayOfWeekChanged"),
            object: nil
        )
    }
    
    @objc private func handleFirstDayOfWeekChanged(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let firstDayOfWeek = userInfo["firstDayOfWeek"] as? Int {
            var newCalendar = Calendar.current
            if firstDayOfWeek == 0 {
                newCalendar.firstWeekday = Calendar.current.firstWeekday
            } else {
                newCalendar.firstWeekday = firstDayOfWeek
            }
            DispatchQueue.main.async {
                self.calendar = newCalendar
            }
        }
    }
    
    func getEffectiveFirstWeekday() -> Int {
        let userDefaults = UserDefaults.standard
        let firstDayOfWeek = userDefaults.integer(forKey: "firstDayOfWeek")
        return firstDayOfWeek == 0 ? Calendar.current.firstWeekday : firstDayOfWeek
    }
} 