//
//  ButtonIn.swift
//  QGS
//
//  Created by Anwar Sarmiento on 11/27/24.
//
import SwiftUI

struct ButtonIn: View {
    @StateObject private var viewModel = RecordViewModel()
    @StateObject private var locationManager = LocationViewController.shared
    @Binding var isLoading: Bool
    
    @State private var errorMessage: String? = nil
    @State private var params: [String: Any] = [:]
    @State private var showSuccessAlert: Bool = false
    @State private var successMessage: String = ""

    let date: Date = Date()

    var body: some View {
        VStack {
            HStack {
                // Botón de Entrada
                Button("Entrada") {
                    isLoading.toggle()
                    record(type: "e")
                }
                .padding()
                .frame(width: 150, height: 50, alignment: .center)
                .background(viewModel.isEntradaEnabled ? Color.green : Color.gray)
                .cornerRadius(10)
                .foregroundColor(.white)
                .disabled(!viewModel.isEntradaEnabled)
                
                // Botón de Salida
                Button("Salida") {
                    isLoading.toggle()
                    record(type: "s")
                }
                .padding()
                .frame(width: 150, height: 50, alignment: .center)
                .background(viewModel.isSalidaEnabled ? Color.red : Color.gray)
                .cornerRadius(10)
                .foregroundColor(.white)
                .disabled(!viewModel.isSalidaEnabled)
            }
            .onAppear {
                locationManager.requestLocationPermission()
                viewModel.updateButtonStates() // Inicializa los estados
            }
        }
        .alert(isPresented: $showSuccessAlert) {
            Alert(
                title: Text("Registro Exitoso"),
                message: Text(successMessage),
                dismissButton: .default(Text("Aceptar"))
            )
        }
    }
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func record(type: String) {
        isLoading = true
        params = [
            "type": type,
            "time": currentTimeString,
            "date": currentDateString,
            "latitude": locationManager.latitude,
            "longitude": locationManager.longitude,
            "address": locationManager.address,
            "employee_id": UserManager.shared.employeeId ?? ""
        ]
        
        viewModel.record(type: type, params: params) { success in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    successMessage = "Registro de \(type == "e" ? "Entrada" : "Salida") guardado con éxito."
                    showSuccessAlert = true
                } else {
                    errorMessage = "Error al registrar \(type)"
                }
            }
        }
    }
}
