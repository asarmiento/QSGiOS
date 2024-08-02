//
//  LoginModel.swift
//  QGS
//
//  Created by Edin Martinez on 7/30/24.
//
import SwiftUI
import Foundation
import UIKit

 class RecordHttpPost:ObservableObject {
  
    
    func sendPostJsonAPI(){
        let url = URL(
            string: "https://api.friendlypayroll.net/api/projects/store-data-time-work"
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
        request.addValue(
            "Bearer 282|zP9ZMYjAdP6YmSdjTpOk3f4Zhz2er1cPHTmNd5wZ18d95326", //Comes from the UserModel table
            forHTTPHeaderField: "Authorization"
        )
        
        let params: [String: Any] = [
            "type": "",// e or s
            "time": "", // 325423223
            "date": "", // 2024-07-31
            "employee_id": "", // 325423223
            "latitude": "", // 39.325423223
            "longitude": "", // -84.325423223
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

