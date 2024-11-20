//
//  TotalHttpGet.swift
//  QGS
//
//  Created by Edin Martinez on 11/18/24.
//

import SwiftUI
import Foundation
import UIKit
import CoreData

class TotalHttpGet:ObservableObject {
    
    @Environment(\.modelContext) var modelContext
    
    @Published var dataReturnTotal: [String: Any]?
    
    func consultTotalResponse(idData:Int){
        
        
        let url =   URL(string:   "https://api.friendlypayroll.net/api/projects/total-time-work-employees/"+String(idData))!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer ", forHTTPHeaderField: "Authorization")
    }
}
