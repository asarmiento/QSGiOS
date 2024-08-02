//
//  QGSApp.swift
//  QGS
//
//  Created by Edin Martinez on 7/24/24.
//

import SwiftUI

@main
struct QGSApp: App {
    
    @State private var locationH = LocationManager()
    var body: some Scene {
        WindowGroup {
            Login()
            
        }.modelContainer(for: [UserModel.self,RecordModel.self])
    }
}
