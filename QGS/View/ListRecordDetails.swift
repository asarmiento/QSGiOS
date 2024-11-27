//
//  ListRecordDetails.swift
//  QGS
//
//  Created by Edin Martinez on 11/19/24.
//
import Foundation
import SwiftUI

struct ListRecordDetails: View {
    
    @State private var details: DetailsResponse
    var body: some View {
        NavigationStack {
            ZStack {
                HeadSecondary(title: "Lista de Registros")
                VStack(alignment: .center, spacing: 3){
                    Spacer(minLength:250)
                    
                    List{
                        
                    }
                }
            }
        }.task {
            getDetails()
        }
    }
    
    func getDetails()   {
            guard let url = URL(string: String(Endpoints.getListDetail+"47")) else{
                print("No access token or employee ID found")
                
                return
            }
            
            let IdString: String = (retrieveEmployeeId())!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 30
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue(String("Bearer "+retrieveAccessToken()!), forHTTPHeaderField: "Authorization")
            // request.httpBody = nil
            
            do {
                
                let task =   URLSession.shared.dataTask(with: request) { data, response, error in
                    showResponse(data)
                    
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
                            
                        }
                    }
                    
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            
                        }
                    }
                }
                task.resume()
            } catch {
                print("Error creating JSON body: \(error)")
                
            }
            
        }
        
        private func retrieveAccessToken() -> String? {
            return UserDefaults.standard.string(forKey: "accessToken")
        }
        private func retrieveEmployeeId() -> String? {
            return String(UserDefaults.standard.integer(forKey: "employeeId"))
        }
        struct DetailsResponse: Codable {
            let time: String
            let date: String
            let type: String
            let hours: String
            
        }
    func showResponse(_ data: Data?) {
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers), let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
               
                print("\n---> response: " + String(decoding: jsonData, as: UTF8.self))
                
            } else {
                print("No response data")
            }
        }
}


   




