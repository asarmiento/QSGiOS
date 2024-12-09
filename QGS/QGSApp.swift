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
    @State private var locationH:LocationViewController = LocationViewController()
    
    var body: some Scene {
        WindowGroup {
            SplashView()
        }   
        .modelContainer(for: [UserModel.self, RecordModel.self])
        
    }
    
    
    
}



