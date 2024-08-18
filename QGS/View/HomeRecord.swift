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
//        guard let createdAt = loginHttpPost.createdAt else {
//            print("createdAt is nil")
//           
//            isEntradaButtonHidden = true
//            return
//        }
        
//        let isVisible = createdAt == currentDateString
//        print("CreatedAt: \(createdAt)")
//        print("Current Date: \(currentDateString)")
//        print("Is Salida Button Visible: \(isVisible)")
//        
//        isSalidaButtonHidden = !isVisible
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                
                Color.myPrimary.ignoresSafeArea()
                Circle().scale(1.8)
                    .foregroundColor(.white.opacity(0.15))
                Circle().scale(1.6)
                    .foregroundColor(.white.opacity(0.15))
                Circle().scale(1.4).foregroundColor(.white)
                VStack{
                    NavigationLink(destination: ListDataRecords() ){
                        Text("Lista de Horas")
                    }
                    
                    Text("Usted podra registrar su ingreso al trabajo y su salida para llegar control de sus horas de trabajo de cada dia").font(.system(size: 20)).font(.title3).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundStyle(Color.black).padding(10).frame(width:370,height: 150,alignment: .center) .navigationTitle("Bienvenido(a)").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).frame(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    VStack {
                        Group {
                            Text(" Longitude: \(locationManager.longitude ?? "39.384974")")
                            Text(" Latitude: \(locationManager.latitude ?? "-84.530861")")
                        }
                        .frame(width: 350, height: 50, alignment: .leading)
                        .font(.title)
                        .border(Color.black)
                        .padding()
                        .padding(.leading, 2)
                        
                        if !isEntradaButtonHidden {
                            Button("Entrada") {
                                let params: [String: Any] = [
                                    "type": "e" ,
                                    "time": getCurrentTime() ,
                                    "date": getCurrentDate() ,
                                    "latitude": locationManager.latitude ?? 39.384974 ,
                                    "longitude": locationManager.longitude ?? -84.530861 ,
                                ]
                                var latitude = locationManager.latitude ?? "39.384974"
                                var longitude = locationManager.longitude ?? "-84.530861"
                                
                                createRecord(type: "e",
                                             time: getCurrentTime(),
                                             date: getCurrentDate() ,
                                             latitude:Double(latitude) ,
                                             longitude:Double(longitude)  )
                                creaturesVM.sendPostJsonAPI(params: params) { success, _ in
                                    if success {
                                        isEntradaButtonHidden = true
                                        
                                        updateSalidaButtonVisibility()
                                    }
                                }
                            }
                            .padding()
                            .frame(width: 300, height: 50, alignment: .center)
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
                                    "latitude": locationManager.latitude ?? 39.384974 ,
                                    "longitude": locationManager.longitude ??  -84.530861 ,
                                ]
                                var latitude = locationManager.latitude ?? "39.384974"
                                var longitude = locationManager.longitude ?? "-84.530861"
                                
                                createRecord(type: "s",
                                             time: getCurrentTime(),
                                             date: getCurrentDate() ,
                                             latitude:Double(latitude) ,
                                             longitude:Double(longitude)  )
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
                            .frame(width: 300, height: 50, alignment: .center)
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
                }
                .frame(alignment: .center)
               
            }
            .onAppear {
                // loginHttpPost.executeAPI(email: "asarmiento@sistemasamigableslatam.com", password: "secret") // Example email and password
            }
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


//#Preview {
//    HomeRecord()
//}



