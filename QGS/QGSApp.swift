//
//  QGSApp.swift
//  QGS
//
//  Created by Edin Martinez on 7/24/24.
//  

import SwiftUI
import SwiftData
import CoreLocation

@main
struct QGSApp: App {
    
    @State private var locationH = LocationManager()
  
    var body: some Scene {
        WindowGroup {
            
            SplashView()
            
        }
    }


 
}



