//
//  CeaturesViewModel.swift
//  QGS
//
//  Created by Edin Martinez on 7/30/24.
//

import Foundation

class CeaturesViewModel: ObservableObject {
    private struct Returned: Codable{
        var token: String
        var employee:String
        var sysconf:String
        var users:[Users]
    }
     struct Users:Codable{
        var _id: Int
        var name: String
        var email: String
        var access_token: String
        var type: Int
    }
    
   @Published var urlString = "https://api.friendlypayroll.net/api/login"
    @Published var token = ""
    @Published var employee = ""
    @Published var creaturesArray: [Users] = []
    
    
    func getData() async{
        print("We are accessing the url \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("We  \(urlString)")
            return
        }
        do{
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let returned = try? JSONDecoder().decode(Returned.self, from: data) else{
                print("JSON Error: could not decode returned JSON data \(urlString)")
                return
            }
            self.token = returned.token
            self.employee = returned.employee
            self.creaturesArray = returned.users
            print("JSON \(returned.employee) bio \(returned.token)")
        } catch{
            print("We aren't accessing the url \(urlString)")
            
        }
    }
}
