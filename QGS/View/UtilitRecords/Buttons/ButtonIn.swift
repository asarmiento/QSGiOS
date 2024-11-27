//
//  ButtonIn.swift
//  QGS
//
//  Created by Edin Martinez on 11/27/24.
//

import SwiftUI

struct ButtonIn: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var creaturesVM = RecordHttpPost()
    @StateObject private var loginHttpPost = LoginHttpPost()
    @State private var isEntradaButtonHidden = false
    @State private var isSalidaButtonHidden = true
    @State private var activeIs = false
    
    @State private var salidaMessage: String? = nil
    var body: some View {
        if !isEntradaButtonHidden {
            Button("Entrada") {
                let params: [String: Any] = [
                    "type": "e" ,
                    "time": getCurrentTime() ,
                    "date": getCurrentDate() ,
                    "latitude": (locationManager.longitude ) ,
                    "longitude": (locationManager.latitude )  ,
                ]
                let latitude = locationManager.latitude
                let longitude = locationManager.longitude
                
                createRecord(type: "e",
                             time: getCurrentTime(),
                             date: getCurrentDate(),
                             latitude:(latitude),
                             longitude:(longitude))
                creaturesVM.sendPostJsonAPI(params: params) { success, _ in
                    if success {
                        isEntradaButtonHidden = true
                        updateSalidaButtonVisibility()
                    }
                }
            }
            .padding()
            .frame(width: 150, height: 50, alignment: .center)
            .background(Color.red)
            .cornerRadius(10)
            .foregroundColor(.white)
        }
        
        if !isSalidaButtonHidden {
            Button("Salida") {
                let params: [String: Any] = [
                    "type": "s" ,
                    "time": getCurrentTime() ,
                    "date": getCurrentDate() ,
                    "latitude": locationManager.latitude  ,
                    "longitude":locationManager.latitude  ,
                ]
                let latitude = (locationManager.latitude )
                let longitude = (locationManager.longitude )
                
                createRecord(type: "s",
                             time: getCurrentTime(),
                             date: getCurrentDate(),
                             latitude:(latitude),
                             longitude:(longitude))
                creaturesVM.sendPostJsonAPI(params: params) { success, message in
                    if success {
                        salidaMessage = message
                        isSalidaButtonHidden = true
                    } else {
                        salidaMessage = "Failed to record exit."
                    }
                }
            }
            .padding()
            .frame(width: 150, height: 50, alignment: .center)
            .background(Color.red)
            .cornerRadius(10)
            .foregroundColor(.white)
        }
        
        if let message = salidaMessage {
            Text(message)
                .font(.title2)
                .foregroundColor(.red)
                .padding()
        }
    }
    
    func updateSalidaButtonVisibility() {
       isSalidaButtonHidden = false
       if loginHttpPost.createdAt != nil {
           isEntradaButtonHidden = true
           return
       }
   }
}
