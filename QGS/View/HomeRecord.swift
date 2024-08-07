//
//  HomeRecord.swift
//  QGS
//
//  Created by Edin Martinez on 7/31/24.
//



import SwiftUI
import CoreLocation
import CoreLocationUI


struct HomeRecord: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var loginHttpPost = LoginHttpPost()
    @StateObject private var creaturesVM = RecordHttpPost()

    @State private var isEntradaButtonHidden = false
    @State private var isSalidaButtonHidden = true
    @State private var salidaMessage: String? = nil

    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func updateSalidaButtonVisibility() {
        isSalidaButtonHidden = false
        guard let createdAt = loginHttpPost.createdAt else {
            print("createdAt is nil")
           
            isEntradaButtonHidden = true
            return
        }
        
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
                Text("Registro").font(.largeTitle.bold())
                Color.myPrimary.ignoresSafeArea()
                Circle().scale(1.8)
                    .foregroundColor(.white.opacity(0.15))
                Circle().scale(1.6)
                    .foregroundColor(.white.opacity(0.15))
                Circle().scale(1.4).foregroundColor(.white)

                VStack {
                    Group {
                        Text(" Longitude: \(locationManager.longitude ?? "N/A") \(loginHttpPost.dataReturnLogin)")
                        Text(" Latitude: \(locationManager.latitude ?? "N/A")")
                    }
                    .frame(width: 350, height: 50, alignment: .leading)
                    .font(.title)
                    .border(Color.black)
                    .padding()
                    .padding(.leading, 2)

                    if !isEntradaButtonHidden {
                        Button("Entrada") {
                            let params: [String: Any] = [
                                "type": "e",
                                "time": getCurrentTime(),
                                "date": getCurrentDate(),
                                "latitude": locationManager.latitude ?? "",
                                "longitude": locationManager.longitude ?? "",
                            ]

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
                                "type": "s",
                                "time": getCurrentTime(),
                                "date": getCurrentDate(),
                                "latitude": locationManager.latitude ?? "",
                                "longitude": locationManager.longitude ?? "",
                            ]

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





