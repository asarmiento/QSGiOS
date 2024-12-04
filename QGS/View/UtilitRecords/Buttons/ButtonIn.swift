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
    @State private var isEntradaButtonHidden = true
    @State private var isSalidaButtonHidden = false
    @State private var activeIs = false
    @State private var latitude: String?
    @State private var longitude: String?
    let date: Date = Date()
    @State private var salidaMessage: String? = nil
    var body: some View {
        VStack {
        HStack{
            Button("Entrada") {
                let params: [String: Any] = [
                    "type": "e" ,
                    "time": currentTimeString ,
                    "date": currentDateString ,
                    "latitude": (locationManager.longitude ) ,
                    "longitude": (locationManager.latitude )  ,
                ]
                
                latitude = (locationManager.latitude )
                longitude = (locationManager.longitude )
                creaturesVM.sendPostJsonAPI(params: params) { success, message in
                    if success {
                        salidaMessage = "La entrada fue registrada con exito."
                        isEntradaButtonHidden = false
                        isSalidaButtonHidden = true
                    } else{
                        salidaMessage = "Genero un error al guardar la entrada favor de intentarlo de nuevo oh reporte lo."
                    }
                }
            }
            .padding()
            .frame(width: 150, height: 50, alignment: .center)
            .background(Color.myPrimary)
            .cornerRadius(10)
            .foregroundColor(.white)
            .disabled(isSalidaButtonHidden)
            
            
            
            Button("Salida") {
                let params: [String: Any] = [
                    "type": "s" ,
                    "time": currentTimeString ,
                    "date": currentDateString ,
                    "latitude": locationManager.latitude  ,
                    "longitude":locationManager.latitude  ,
                ]
                latitude = (locationManager.latitude )
                longitude = (locationManager.longitude )
                
                
                creaturesVM.sendPostJsonAPI(params: params) { success, message in
                    if success {
                        salidaMessage = "La Salida fue registrada con exito."
                        isSalidaButtonHidden = false
                        isEntradaButtonHidden = false
                        
                    } else {
                        salidaMessage = "Failed to record exit."
                    }
                }
            }
            .padding()
            .frame(width: 150, height: 50, alignment: .center)
            .background(Color.myPrimary)
            .cornerRadius(10)
            .foregroundColor(.white)
            .disabled(isEntradaButtonHidden)
            
           }
        
            if salidaMessage != nil {
                let message:String = salidaMessage!
       
                Text(message)
                    .font(.title2)
                    .foregroundColor(.red)
                    .padding()
              //  salidaMessage = nil
            }
        }
    }
    
 
    private  var currentDateString: String {
       let formatter = DateFormatter()
       formatter.dateFormat = "yyyy-MM-dd"
       return formatter.string(from: date)
   }
    private  var currentTimeString: String {
       let formatter = DateFormatter()
       formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date )
   }
}
