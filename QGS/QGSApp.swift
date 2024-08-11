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
     let datecreatAt = UserDefaults.standard.string(forKey: "createdAt")
    @State private var locationH = LocationManager()
  
    var body: some Scene {
        WindowGroup {
            
           if accessToken != nil && datecreatAt == currentDateString {
               HomeRecord()
            }else{
                Login()
            }
            
        }.modelContainer(for: [UserModel.self,RecordModel.self])
    }
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

 
}



