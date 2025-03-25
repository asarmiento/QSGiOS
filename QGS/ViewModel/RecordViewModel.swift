//
//  RecordViewModel.swift
//  QGS
//
//  Created by Anwar Sarmiento on 12/9/24.
//
import SwiftUI
import SwiftData

import SwiftUI
import SwiftData

class RecordViewModel: ObservableObject {
    // Variables existentes
    @Published var isEntradaEnabled: Bool = true
    @Published var isSalidaEnabled: Bool = false
    @Published var hasEntradaDeHoy: Bool = false
    @Published var showSuccessAlert: Bool = false
    
    // Agregamos un almacenamiento para la fecha verificada por última vez
    private var lastCheckDate: String {
        get { UserDefaults.standard.string(forKey: "LastCheckDate") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "LastCheckDate") }
    }

    // MARK: - Actualizar estados
    func updateButtonStates() {
        // Lógica existente para saber si hay registro de "Entrada" o "Salida"
        let entradaExists = RecordManager.shared.getRecordExists(for: "Entrada")
        let salidaExists = RecordManager.shared.getRecordExists(for: "Salida")
        
        DispatchQueue.main.async {
            // Entrada habilitada si no existe “Entrada”
            self.isEntradaEnabled = (entradaExists == 0)
            // Salida habilitada si “Entrada” existe pero “Salida” no
            self.isSalidaEnabled = (entradaExists > 0 && salidaExists == 0)
            
            // Guardar la fecha de hoy como verificada
            self.lastCheckDate = self.todayString()
        }
    }
    
    // MARK: - Verificar si cambió el día
    func checkIfNewDay() {
        let today = todayString()
        // Si la fecha actual difiere de la guardada, recargamos estados
        if today != lastCheckDate {
            updateButtonStates()
        }
    }
    
    // MARK: - Registrar entrada/salida
    func record(type: String, params: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: EndPoints.storeRecord) else {
            print("URL inválida")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserManager.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params)
        } catch {
            print("Error al serializar parámetros: \(error)")
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Error de red: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            guard let data = data else {
                print("No se recibieron datos")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            // Depuración: Imprimir respuesta JSON
            if let jsonString = String(data: data, encoding: .utf8) {
                print("JSON recibido: \(jsonString)")
            }
            
            do {
                let response = try JSONDecoder().decode(RecordResponse.self, from: data)
                DispatchQueue.main.async {
                    if response.success {
                        if let recordData = response.data {
                            RecordManager.shared.saveRecord(recordData: recordData)
                        }
                        // Actualizar estados de los botones según el tipo de registro
                        self?.updateButtonStatesAfterRecord(type: type)
                        completion(true)
                    } else {
                        print("Error del servidor: \(response.message)")
                        completion(false)
                    }
                }
            } catch {
                print("Error al decodificar: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }.resume()
    }
    
    // MARK: - Actualizar estados tras un registro
    private func updateButtonStatesAfterRecord(type: String) {
        if type == "e" {
            isEntradaEnabled = false
            isSalidaEnabled = true
        } else if type == "s" {
            isEntradaEnabled = false
            isSalidaEnabled = false
        }
    }
    
    // MARK: - Helpers
    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
