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

 class LoginHttpPost: NSObject, ObservableObject {
     
     @Environment(\.modelContext) var context
     @Environment(\.dismiss) private var dismiss
     @State var modelUserData: UserModel?
     
    
    func executeAPI(email:String, password:String){
        let url = URL(
            string: "https://api.friendlypayroll.net/api/login"
        )!
        var request = URLRequest(
            url: url
        )
        request.httpMethod = "POST"
        request.addValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        request.addValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )
        
        let params: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(
                withJSONObject: params,
                options: []
            )
            
            let task = URLSession.shared
            task.dataTask(with: request) { data, response, error in
              
                guard let data = data else {
                    return
                }           
             
                do{
                    guard  let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else{return}
                    
                    let loginJson = dataLogin(json: json)
                    let dataToSave = UserModel(name: loginJson.name, email: loginJson.email, sysconf:  loginJson.sysconf,token: loginJson.token)
                    
             
                } catch let error{
                    print(error)
                }
                
                //  self.showResponse(data)
               
                if let response = response {
                    let httpResponse = response as! HTTPURLResponse
                    print(
                        httpResponse.allHeaderFields
                    )
                }
                
                if let error = error {
                    print(
                        error.localizedDescription
                    )
                }
                
            }.resume()
               
       

        } catch {
            print(
                "Error creating JSON body: \(error)"
            )
            
        }
        
    }
    
  
}


struct dataLogin {
    let name: String
    let email: String
    let token: String
    let sysconf: Int
    
    init(json: [String: Any]){
        name = json["name"] as? String ?? ""
        email = json["email"] as? String ?? ""
        sysconf = json["sysconf"] as? Int ?? -1
        token = json["token"] as? String ?? ""
    }
}

struct Users {
    let name: String
    let email: String
    let sysconfId: Int
    init(json: [String: Any]){
        name = json["name"] as? String ?? ""
        email = json["email"] as? String ?? ""
        sysconfId = json["sysconfId"] as? Int ?? -1
       // employees = json["name"] as? String ?? ""
    }
}
struct Employees{
    let name: String
    let email: String
    
   
}

struct Sysconfs{
    let name: String
    let card: String
    let url: String
}
