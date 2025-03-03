//
//  RecordViewModel.swift
//  QGS
//
//  Created by Anwar Sarmiento on 12/9/24.
//
import SwiftUI
import SwiftData

class RecordViewModel: ObservableObject {
    @Published var isEntradaEnabled: Bool = true
    @Published var isSalidaEnabled: Bool = false
    @Published var hasEntradaDeHoy: Bool = false
    @Published var showSuccessAlert: Bool = false
    
    func updateButtonStates() {
        let entradaExists = RecordManager.shared.getRecordExists(for: "Entrada")
        let salidaExists = RecordManager.shared.getRecordExists(for: "Salida")
        
        DispatchQueue.main.async {
            // Entrada habilitada si no existe, salida habilitada si ya existe entrada pero no salida
            self.isEntradaEnabled = (entradaExists == 0)
            self.isSalidaEnabled = (entradaExists > 0 && salidaExists == 0)
        }
    }
    
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
    
    private func updateButtonStatesAfterRecord(type: String) {
        if type == "e" {
            isEntradaEnabled = false
            isSalidaEnabled = true
        } else if type == "s" {
            isEntradaEnabled = false
            isSalidaEnabled = false
        }
    }
}
