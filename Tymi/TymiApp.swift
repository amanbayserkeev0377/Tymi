//
//  TymiApp.swift
//  Tymi
//
//  Created by Aman on 29/3/25.
//

import SwiftUI

@main
struct TymiApp: App {
    @StateObject private var habitStore = HabitStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(habitStore)
        }
    }
}
