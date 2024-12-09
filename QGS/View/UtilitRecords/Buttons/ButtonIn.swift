//
//  ButtonIn.swift
//  QGS
//
//  Created by Edin Martinez on 11/27/24.
//

import SwiftUI
import SwiftData

struct ButtonIn: View {
    //  @Environment(\.modelContext) private var modelContext
   // @StateObject private var locationManager = LocationViewController()
    @StateObject private var locationManager = LocationViewController.shared
       @State private var showLocationAlert = false
    @StateObject private var creaturesVM = RecordHttpPost()
    @State private var isTwoButtonHidden = false
    @State private var activeIs = false
    @State private var isRecordSuccessful = false
    @State private var latitude: String?
    @State private var longitude: String?
    @State var isButtonDisabled = false
    @State var errorMessage:String? = nil
    @State var params: [String: Any] = [:]
    let date: Date = Date()
    @State private var salidaMessage: String? = nil
    var body: some View {
        VStack {
            HStack{
                let typeToCheck = "Entrada"
                if RecordManager.shared.getRecordExists(for: typeToCheck) == 0 {
                   
                        Button("Entrada") {
                           // if handleLocationCheck  {
                                isRecordSuccessful = true
                                record(type: "e")
                                
                                isRecordSuccessful = false
                           // }
                        }
                        .padding()
                        .frame(width: 150, height: 50, alignment: .center)
                        .background(Color.init(red: 0.275, green: 0.581, blue: 0.142))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .onAppear {
                            
                        }
                    
                } else {
                    Button("Entrada") {}.padding()
                        .frame(width: 150, height: 50, alignment: .center)
                        .background(Color.init(red: 0.275, green: 0.581, blue: 0.142).opacity( 0.2))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .disabled(true)
                }

             
                
                
                    let typeToCheckS = "Salida"
                if RecordManager.shared.getRecordExists(for: typeToCheckS) == 0 {
                    Button("Salida") {
                    //    if handleLocationCheck {
                            isRecordSuccessful = true
                            salidaMessage = ""
                            
                            
                            record(type:"s")
                            isRecordSuccessful = false
                       // }
                    }
                    .padding()
                    .frame(width: 150, height: 50, alignment: .center)
                    .background(Color.init(red: 0.918, green: 0.0405, blue: 0.0405))
                    .cornerRadius(10)
                    .foregroundColor(.white).onAppear() {
                        RecordManager.shared.refreshRecord()
                    }
                }
                else{
                    
                    Button("Salida") {}.padding()
                        .frame(width: 150, height: 50, alignment: .center)
                        .background(Color.init(red: 0.918, green: 0.0405, blue: 0.0405).opacity( 0.2))
                        .cornerRadius(10)
                        .foregroundColor(.white).disabled(true)
                }
                
                if salidaMessage != nil {
                    let message:String = salidaMessage!
                    
                    Text(message)
                        .font(.title2)
                        .foregroundColor(.red)
                        .padding()
                    //  salidaMessage = nil
                }
                
                if isRecordSuccessful {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(2)
                        .padding(.top, 50)
                }
            }.onAppear {
                locationManager.requestLocationPermission()
                RecordManager.shared.refreshRecord()
            }
        }
    }
    
    private var isEntradaButtonHidden: Int {
        return  RecordManager.shared.getRecordExists(for: "Entrada")
    }
    private var isSalidaButtonHidden: Int {
        return  RecordManager.shared.getRecordExists(for: "Salida")
    }
    private func handleLocationCheck(action: @escaping () -> Void) {
//         if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
//             action()
//         } else {
//             showLocationAlert = true
//         }
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
    private var authToken: String? {
        UserManager.shared.authToken
    }
    
    private var employeeId: String? {
        UserManager.shared.employeeId
    }
    
    private var getRecord: Bool {
        return    RecordManager.shared.getRecordExistsfor()
    }
    
    func record(type:String) {
        params = [
            "type": type ,
            "time": currentTimeString ,
            "date": currentDateString ,
            "latitude": (locationManager.latitude ) ,
            "longitude": (locationManager.longitude )  ,
            "address": locationManager.address  ,
            "employee_id": (employeeId)
        ]
        APIServiceRecord.shared.record(params: params) { result in
            switch result {
            case .success(let response):
                if response.success { // Verifica la clave "success"
                    // Usa los datos contenidos en "data"
                    let recordData = response.data
                    print("Entrada registrada correctamente: \(recordData)")
                    RecordManager.shared.saveRecord(from: recordData)
                    
                        RecordManager.shared.refreshRecord()
                    DispatchQueue.main.async {
                        isRecordSuccessful = false
                    }
                } else {
                    DispatchQueue.main.async {
                        print("Error: \(response.message)")
                        errorMessage = response.message
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    print("Error al procesar el registro: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    
}
