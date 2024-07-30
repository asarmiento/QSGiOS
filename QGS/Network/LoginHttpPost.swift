//
//  LoginModel.swift
//  QGS
//
//  Created by Edin Martinez on 7/30/24.
//
import SwiftUI
import Foundation
import UIKit

 class LoginHttpPost:ObservableObject {
  
    
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
                self.showResponse(data)
               
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
    
    func showResponse(_ data: Data?) {
           if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers), let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
               print("\n---> response: " + String(decoding: jsonData, as: UTF8.self))
                   
           }else{
               print("No esta registrando el login")
           }
        
       }
}


struct dataLogin:  Decodable {
    let status: Bool?
    let message: String?
    let user: [Users]?
    let sysconfs: [Sysconfs]?
    let tokenL: String?
}

struct Users: Decodable {
    let name: String
    let email: String
    let sysconfId: Int
    let employees:[Employees]
    
}
struct Employees: Decodable{
    let name: String
    let email: String
}

struct Sysconfs: Decodable{
    let name: String
    let card: String
    let url: String
}
