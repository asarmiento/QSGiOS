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
     let accessToken = UserDefaults.standard.string(forKey: "accessToken")
    @State private var locationH = LocationManager()
    var body: some Scene {
        WindowGroup {
//            if accessToken != nil {
//                HomeRecord()
//            }else{
                Login()
          //  }
            
        }.modelContainer(for: [UserModel.self,RecordModel.self])
    }
    
  
}



