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
//    let container: ModelContainer = {
//        let schema = Schema([UserModel.self, RecordModel.self])
//        let container = try ModelContainer(for: schema, configurations: [])
//        return container
//    }()
    
    @State private var locationH = LocationViewController()
    var body: some Scene {
        WindowGroup {
            Login()
            
        }//.modelContainer(container)
        .modelContainer(for: [UserModel.self,RecordModel.self])
    }
}
