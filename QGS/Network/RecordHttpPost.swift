//
//  LoginModel.swift
//  QGS
//
//  Created by Edin Martinez on 7/30/24.
//
import SwiftUI
import Foundation
import UIKit
import SwiftData


class RecordHttpPost: ObservableObject {
    @Environment(\.modelContext) private var context
    @Published var isLoading: Bool = false
    func sendPostJsonAPI(params: [String: Any], completion: @escaping (Bool, String?) -> Void) {
        
        // Optenemos el id de empleado y el token
        guard let employeeId = UserManager.shared.employeeId, let accessToken = UserManager.shared.authToken else {
            print("No se pudo obtener el usuario o el token.")
            return
        }
        let url = URL(string: "https://api.friendlypayroll.net/api/projects/store-data-time-work")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        print("Authorization Header: Bearer \(accessToken)")
        
        var mutableParams = params
        mutableParams["employee_id"] = employeeId
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: mutableParams, options: [])
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                // self.showResponse(data)
                if let data = data {
                    print("Raw response data: \(String(data: data, encoding: .utf8) ?? "Invalid UTF-8")")
                }
                if let response = response {
                    let httpResponse = response as! HTTPURLResponse
                    print("HTTP Response Status Code: \(httpResponse.statusCode)")
                    //  print("Response Headers: \(httpResponse.allHeaderFields)")
                    
                    var success = false
                    var message: String? = nil
                    print("Proceso ... cosde")
                    if (200...299).contains(httpResponse.statusCode) {
                        success = true
                        
                        print("Proceso ... cosde linea 51")
                        // Parse the response message
                        if let data = data,
                           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let dataDetails = json["data"] as? [String: Any] {
                            print("Proceso ... cosde linea 56")
                            message = json["message"] as? String
                            //  let dataDetails = json["data"] as? [String: Any]
                            print(" estadmos revisando data \(String(describing: dataDetails))")
                        }
                    }
                    DispatchQueue.main.async {
                        completion(success, message)
                    }
                }
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion(false, nil)
                    }
                }
            }
            task.resume()
        } catch {
            print("Error creating JSON body: \(error)")
            completion(false, nil)
        }
    }
    
    
    private func showResponse(_ data: Data?) {
        if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers), let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            print("\n---> response: " )
        } else {
            print("No response data")
        }
    }
    
    
}


