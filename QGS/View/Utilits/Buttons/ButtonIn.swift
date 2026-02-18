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
    @State private var showOutOfTimeAlert: Bool = false
    @State private var showObservationSheet: Bool = false
    @State private var showSessionExpiredAlert: Bool = false
    @State private var observation: String = ""
    @State private var pendingRecordType: String? = nil

    let date: Date = Date()

    var body: some View {
        VStack {
            HStack {
                // Botón de Entrada
                Button("Entrada") {
                    checkTimeAndRecord(type: "e")
                }
                .padding()
                .frame(width: 150, height: 50, alignment: .center)
                .background(viewModel.isEntradaEnabled ? Color.green : Color.gray)
                .cornerRadius(10)
                .foregroundColor(.white)
                .disabled(!viewModel.isEntradaEnabled)
                
                // Botón de Salida
                Button("Salida") {
                    checkTimeAndRecord(type: "s")
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
        .alert("Fuera de horario", isPresented: $showOutOfTimeAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Continuar") {
                showObservationSheet = true
            }
        } message: {
            Text(NSLocalizedString("Por favor, escriba el motivo por el que está marcando fuera del horario normal", comment: ""))
        }
        .alert("Sesión Expirada", isPresented: $showSessionExpiredAlert) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text("Su sesión ha expirado. Por favor, cierre sesión e inicie sesión nuevamente para continuar.")
        }
        .sheet(isPresented: $showObservationSheet) {
            ObservationInputView(
                observation: $observation,
                onSubmit: {
                    if let type = pendingRecordType {
                        isLoading = true
                        record(type: type)
                    }
                    showObservationSheet = false
                },
                onCancel: {
                    pendingRecordType = nil
                    showObservationSheet = false
                }
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
    
    private func isWithinNormalHours(type: String) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour, .minute], from: now)
        
        guard let hour = components.hour, let minute = components.minute else {
            return false
        }
        
        let timeInMinutes = hour * 60 + minute
        
        if type == "e" {
            // Horario normal de entrada: 6:30am a 8:30am (390-510 minutos desde medianoche)
            return timeInMinutes >= 360 && timeInMinutes <= 510
        } else {
            // Horario normal de salida: 3:30pm a 5:00pm (930-1020 minutos desde medianoche)
            return timeInMinutes >= 900 && timeInMinutes <= 1020
        }
    }
    
    private func checkTimeAndRecord(type: String) {
        if isWithinNormalHours(type: type) {
            isLoading = true
            record(type: type)
        } else {
            pendingRecordType = type
            showOutOfTimeAlert = true
        }
    }
    
    private func record(type: String) {
        guard let employeeId = UserManager.shared.getEmployeeId, !employeeId.isEmpty else {
            isLoading = false
            showSessionExpiredAlert = true
            return
        }

        params = [
            "type": type,
            "time": currentTimeString,
            "date": currentDateString,
            "latitude": locationManager.latitude,
            "longitude": locationManager.longitude,
            "address": locationManager.address,
            "employee_id": employeeId
        ]

        // Agregar observación solo si no está vacía
        if !observation.isEmpty {
            params["observation"] = observation
        }

        viewModel.record(type: type, params: params) { success in
            DispatchQueue.main.async {
                isLoading = false
                observation = "" // Limpiar la observación
                pendingRecordType = nil
                
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

// Vista para ingresar la observación
struct ObservationInputView: View {
    @Binding var observation: String
    var onSubmit: () -> Void
    var onCancel: () -> Void
    @State private var showError: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(NSLocalizedString("Ingrese el motivo de marcación fuera de horario", comment: ""))
                    .font(.headline)
                    .padding(.top)
                
                TextEditor(text: $observation)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                    .frame(height: 150)
                
                if showError {
                    Text(NSLocalizedString("Debe indicar un motivo para registrar fuera del horario normal", comment: ""))
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitle("Fuera de horario", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancelar") {
                    onCancel()
                },
                trailing: Button("Guardar") {
                    if observation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        showError = true
                    } else {
                        showError = false
                        onSubmit()
                    }
                }
            )
        }
    }
}
