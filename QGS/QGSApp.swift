//
//  QGSApp.swift
//  QGS
//
//  Created by Edin Martinez on 7/24/24.
//  

import SwiftUI
import SwiftData
import CoreLocation
import CoreLocationUI

@main
struct QGSApp: App {
    
    @State private var locationH = LocationManager()
  
    var body: some Scene {
        WindowGroup {
            
            SplashView()
            
        }
    }


 
}



