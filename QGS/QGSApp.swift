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
    
    @State private var locationH:LocationManager = LocationManager()
 
    var body: some Scene {
        WindowGroup {
            SplashView()
        }.modelContainer(for:[RecordModel.self, UserModel.self])
    }


 
}



