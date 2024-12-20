//
//  ButtonIn.swift
//  QGS
//
//  Created by Edin Martinez on 11/27/24.
//

import SwiftUI
import SwiftData

struct ButtonIn: View {
    @StateObject private var viewModel = RecordViewModel()
    @StateObject private var locationManager = LocationViewController.shared
    @Binding var isLoading: Bool
    @State private var showLocationAlert = false
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
                Button("Entrada") {
                    
                    isLoading.toggle()
                    record(type: "e")
                    
                }
                .padding()
                .frame(width: 150, height: 50, alignment: .center)
                .background(
                    viewModel.isEntradaEnabled ? Color.green : Color.gray
                )
                .cornerRadius(10)
                .foregroundColor(.white)
                .disabled(!viewModel.isEntradaEnabled)
                
                
                Button("Salida") {
                    isLoading.toggle()
                    
                    record(type:"s")
                   
                }
                .padding()
                .frame(width: 150, height: 50, alignment: .center)
                .background(viewModel.isSalidaEnabled ? Color.red : Color.gray)
                .cornerRadius(10)
                .foregroundColor(.white)
                .disabled(!viewModel.isSalidaEnabled)
                
                
            
                
             
            }.onAppear {
                locationManager.requestLocationPermission()
                viewModel.updateButtonStates()
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
    private var authToken: String? {
        UserManager.shared.authToken
    }
    
    private var employeeId: String? {
        UserManager.shared.employeeId
    }
    
    private var getRecord: Bool {
        return RecordManager.shared.getRecordExistsFor()
    }
    private func record(type: String) {
        isLoading = true
        params = [
            "type": type,
            "time": currentTimeString,
            "date": currentDateString,
            "latitude": locationManager.latitude ?? "",
            "longitude": locationManager.longitude ?? "",
            "address": locationManager.address ?? "",
            "employee_id": UserManager.shared.employeeId ?? ""
        ]
        
        viewModel.record(type: type, params: params) { success in
            DispatchQueue.main.async {
                if success {
                    viewModel.updateButtonStates()
                    isLoading = false
                } else {
                    errorMessage = "Error al registrar \(type)"
                }
            }
        }
    }
    
    
}
