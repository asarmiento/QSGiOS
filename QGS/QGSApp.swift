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
    
    @State private var locationH = LocationManager()
    let container: ModelContainer = {
        let schema = Schema([RecordModel.self, UserModel.self])
        let container = try! ModelContainer(for: schema,configurations: [])
        return container
    }()
    var body: some Scene {
        WindowGroup {
            
            SplashView()
            
        }.modelContainer(container)
    }


 
}



