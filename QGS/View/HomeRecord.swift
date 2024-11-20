//
//  HomeRecord.swift
//  QGS
//
//  Created by Edin Martinez on 7/31/24.
//



import SwiftUI
import CoreLocation
import CoreLocationUI
import CoreData


struct HomeRecord: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var loginHttpPost = LoginHttpPost()
    @StateObject private var creaturesVM = RecordHttpPost()
    
    @State private var isEntradaButtonHidden = false
    @State private var activeIs = false
    @State private var isSalidaButtonHidden = true
    @State private var salidaMessage: String? = nil
    
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func updateSalidaButtonVisibility() {
        isSalidaButtonHidden = false
        if loginHttpPost.createdAt != nil {
            
            isEntradaButtonHidden = true
            return
        }

    }
    
    var body: some View {
        NavigationView {
            ZStack {
                HeadSecondary(title: "Entrada o Salida")
            VStack(alignment: .center, spacing: 3){
                    Text("Debe presionar el boton de entrada o salida, para poder registrar su ingreso o su salida del trabajo").font(.system(size: 20)).font(.title3).foregroundStyle(Color.myPrimary).padding(10).frame(width:370,height: 150,alignment: .center).contentMargins(5)
                    VStack {
                        
                        BoxGPS()
                        HStack{
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
                     }
                        HStack{
                            Group{
                                    Button("Ver Detalle") {
                                        //ListRecordDetails()
                                      //  NavigationLink(destination: ListRecordDetails())
                                    }
                             //
                                    Button("Ver Totales") {
                                       
                                    }
                              //  NavigationLink(destination:{ListRecordTotals()},Label:{})
                               }.padding()
                                .frame(width: 150, height: 50, alignment: .center)
                                .background(Color.red)
                                .cornerRadius(10)
                                .foregroundColor(.white)
                        }
                    
                    NavigationLink(destination: ListDataRecords() ){
                            
                        }
                        
                        if let message = salidaMessage {
                            Text(message)
                                .font(.title2)
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                }
                .frame(alignment: .center)
                
            }
            //            .onAppear {
            //                // loginHttpPost.executeAPI(email: "asarmiento@sistemasamigableslatam.com", password: "secret") // Example email and password
            //            }
            //        .onChange(of: loginHttpPost.createdAt) { _ in
            //
            //            updateSalidaButtonVisibility()
            //        }
            
        }
    }
    
    func createRecord(type: String,time:String,date:String,latitude:Double?,longitude:Double?){
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: date)
        let record = RecordEntity(context: PersistentStorage.shared.context)
        record.id = UUID()
        record.type = type
        record.date = date
        record.times = time
        record.latitude = latitude ?? 39.384974
        record.longitude = longitude ?? -84.530861
        record.willSave()
        PersistentStorage.shared.saveContext()
        print("Resultado de DB \(record)")
    }
    private func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HHmmss"
        return formatter.string(from: Date())
    }
    
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}


#Preview {
    HomeRecord()
}



