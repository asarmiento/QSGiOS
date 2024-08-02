//
//  LoginModel.swift
//  QGS
//
//  Created by Edin Martinez on 7/30/24.
//
import SwiftUI
import Foundation
import UIKit



class RecordHttpPost: ObservableObject {
    
    func sendPostJsonAPI(params: [String: Any], completion: @escaping (Bool, String?) -> Void) {
        guard let accessToken = retrieveAccessToken(),
              let employeeId = retrieveEmployeeId() else {
            print("No access token or employee ID found")
            completion(false, nil) // Indicate failure
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
                self.showResponse(data)
                
                if let response = response {
                    let httpResponse = response as! HTTPURLResponse
                    print("HTTP Response Status Code: \(httpResponse.statusCode)")
                    print("Response Headers: \(httpResponse.allHeaderFields)")
                    
                    var success = false
                    var message: String? = nil
                    
                    if (200...299).contains(httpResponse.statusCode) {
                        success = true
                        
                        // Parse the response message
                        if let data = data,
                           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            message = json["message"] as? String
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
    
    private func retrieveAccessToken() -> String? {
        return UserDefaults.standard.string(forKey: "accessToken")
    }
    
    private func retrieveEmployeeId() -> Int? {
        return UserDefaults.standard.integer(forKey: "employeeId")
    }
    
    private func showResponse(_ data: Data?) {
        if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers), let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            print("\n---> response: " + String(decoding: jsonData, as: UTF8.self))
        } else {
            print("No response data")
        }
    }
}


