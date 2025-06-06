import Foundation

enum AppConfig {
    
    // MARK: - App Version Detection
    
    /// Определяет текущую версию приложения по Bundle ID
    static var current: AppVersion {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            return .production
        }
        
        if bundleId.contains(".dev") {
            return .development
        } else {
            return .production
        }
    }
    
    // MARK: - App Versions
    
    enum AppVersion {
        case production
        case development
        
        /// CloudKit Container ID для каждой версии
        var cloudKitContainerID: String {
            switch self {
            case .production:
                return "iCloud.com.amanbayserkeev.teymiahabit"
            case .development:
                return "iCloud.com.amanbayserkeev.teymiahabit.dev"
            }
        }
        
        /// Название для логов
        var displayName: String {
            switch self {
            case .production:
                return "Production"
            case .development:
                return "Development"
            }
        }
        
        /// Показывать ли debug информацию
        var isDebugEnabled: Bool {
            switch self {
            case .production:
                return false
            case .development:
                return true
            }
        }
    }
}
