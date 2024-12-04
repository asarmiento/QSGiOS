////
////  TotalHttpGet.swift
////  QGS
////
////  Created by Edin Martinez on 11/18/24.
////
//
//import SwiftUI
//import Foundation
//import UIKit
//import CoreData
//
//class TotalHttpGet:ObservableObject {
//    
//    @Environment(\.modelContext) var modelContext
//    var idData:Int?
//    @Published var dataReturnTotal: [String: Any]?
//    
//    func consultTotalResponse(idData:Int){
//        
//        
//        let url =   URL(string:   Endpoints.getListTotal+String(idData))!
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.addValue("application/json", forHTTPHeaderField: "Accept")
//        request.addValue("Bearer ", forHTTPHeaderField: "Authorization")
//        
//        request.httpBody = nil
//        request.timeoutInterval = 10
//        
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data else { return }
//            do {
//                let json = try JSONSerialization.jsonObject(with: data, options: [])
//                self.dataReturnTotal = json as? [String: Any]
//               // print(self?.dataReturnTotal)
//            } catch {
//                print(error)
//            }
//        }
//    }
//}
