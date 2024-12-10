//
//  QGSApp.swift
//  QGS
//
//  Created by Edin Martinez on 7/24/24.
//
import SwiftUI
import SwiftData

@main
struct QGSApp: App {
    init() {
            _ = DataManager.shared
        }
    var body: some Scene {
        WindowGroup {
            SplashView()
        }
        .modelContainer(for: [UserModel.self, RecordModel.self])
    }
    
    
}






