//
//  TymiApp.swift
//  Tymi
//
//  Created by Aman on 29/3/25.
//

import SwiftUI

@main
struct TymiApp: App {
    @StateObject private var habitStore = HabitStoreManager()
        
    var body: some Scene {
        WindowGroup {
            TodayView()
                .environmentObject(habitStore)
                .onAppear {
                    // Очищаем старые данные при запуске приложения
                    let thirtyDaysAgo = Calendar.current.date(byAddingDays: -30, to: Date()) ?? Date()
                    habitStore.cleanOldData(before: thirtyDaysAgo)
                    
                    // Запрашиваем разрешение на уведомления
                    NotificationService.shared.requestAuthorization()
                }
        }
    }
}

private extension Calendar {
    func date(byAddingDays days: Int, to date: Date) -> Date? {
        return self.date(byAdding: .day, value: days, to: date)
    }
}
