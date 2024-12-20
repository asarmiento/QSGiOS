//
//  RecordViewModel.swift
//  QGS
//
//  Created by Edin Martinez on 12/9/24.
//

import SwiftUI
import SwiftData

class RecordViewModel: ObservableObject {
    @Published var isEntradaEnabled: Bool = true
    @Published var isSalidaEnabled: Bool = true
    
    func updateButtonStates() {
        let entradaExists = RecordManager.shared.getRecordExists(for: "Entrada")
        let salidaExists = RecordManager.shared.getRecordExists(for: "Salida")
        
        DispatchQueue.main.async {
            self.isEntradaEnabled = (entradaExists == 0)
            self.isSalidaEnabled = (salidaExists == 0)
        }
    }
    
    func record(type: String, params: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: Endpoints.storeRecord) else {
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
            
            // Debug: Imprimir respuesta JSON
            if let jsonString = String(data: data, encoding: .utf8) {
                print("JSON recibido: \(jsonString)")
            }
            
            do {
                let response = try JSONDecoder().decode(RecordResponse.self, from: data)
                DispatchQueue.main.async {
                    if response.success {
                        if let recordData = response.data {
                            RecordManager.shared.saveRecord(from: recordData)
                        }
                        completion(true)
                    } else {
                        print("Error del servidor: \(response.message)")
                        completion(false)
                    }
                }
            } catch {
                print("Error al decodificar: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, _):
                        print("Llave no encontrada: \(key)")
                    default:
                        print("Otro error de decodificación")
                    }
                }
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }.resume()
    }
}
