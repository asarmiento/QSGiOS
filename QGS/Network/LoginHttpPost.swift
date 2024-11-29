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
struct UserJson: Hashable, Codable {
    let token: String
    let email:String
    let sysconf:String
    let name :String
    let employeeId : String
}
class LoginHttpPost: ObservableObject {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \UserModel.id) var userModel: [UserModel]
    @Published var loginSuccess: Bool = false
    @Published var createdAt: String? // Property to store createdAt date
    @Published var dataReturnLogin: [String: Any]?
    @Published var loginUser: UserModel?
    
    init() {
        // Retrieve createdAt from UserDefaults if it exists
        self.createdAt = UserDefaults.standard.string(forKey: "createdAt")
    }
    
    func  executeAPI(email: String, password: String) async{
        
        let url =   URL(string:   Endpoints.login)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let params: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
            
            let task: URLSessionDataTask = URLSession.shared.dataTask(with: request) { data, response, error in

                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any],
                   let status = json["status"] as? Bool {
                    self.showResponse(data: data)
//                    let est = json as? [String: Any]
//                    print(" revisaremos resultado de login sin token \((est) ))")
                    
                    DispatchQueue.main.async {
                        self.loginSuccess = status
                    }
                    
                    
                } else {
                    DispatchQueue.main.async {
                        self.loginSuccess = false
                    }
                    print("Login not registered")
                }
                
                if let error = error {
                    print(error.localizedDescription)
                }
            }
            task.resume()
        } catch {
            print("Error creating JSON body: \(error)")
        }
    }
    
    func showResponse(data: Data?) {
        guard let data = data else {
            print("No data received")
            return
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            print("Failed to parse JSON")
            return
        }
  
        guard let token = json["token"] as? String,
              let email = json["email"] as? String,
              
              let name = json["name"] as? String,
              let user = json["user"] as? [String: Any],
              let employee = user["employee"] as? [String: Any],
              let employeeId = employee["id"] as? Int,
              let sysconf = user["sysconf_id"] as? Int,
              let createdAtString = user["created_at"] as? String else {
            print("Login registration failed")
            return
        }
        
        loginUser = UserModel(name: name,
                                  email: email,
                                  employeeId:  String(employeeId),
                                  systemId:  String(sysconf),
                                  token:  token)
        print("revisando Model: \(loginUser)")
        modelContext.insert(loginUser!)
        dismiss()
        
        storeAccessToken(token)
        storeEmployeeId(employeeId)
        storeCreatedAt(createdAtString)
        
        
        DispatchQueue.main.async {
            self.createdAt = createdAtString
        }
    }
    
    func storeCreatedAt(_ createdAt: String) {
        UserDefaults.standard.set(createdAt, forKey: "createdAt")
    }
    
    func storeAccessToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "accessToken")
    }
    
    func storeEmployeeId(_ employeeId: Int) {
        UserDefaults.standard.set(employeeId, forKey: "employeeId")
    }
}





