//
//  APIServiceRecord.swift
//  QGS
//
//  Created by Edin Martinez on 12/6/24.
//
import Foundation


struct RecordResponse: Decodable {
    let success: Bool
    let message: String
    let data: RecordData
}

struct RecordData: Decodable {
    let address: String
    let longitude: String
    let latitude: String
    let employee_id: Int
    let time: String
    let type: String
    let work_type_id: Int
    let project_id: Int
    let dist: String
    let updated_at: String
    let created_at: String
    let id: Int
    let date: String
}


class APIServiceRecord {
    static let shared = APIServiceRecord()
    // Contexto para cambios

    private let baseURL = Endpoints.postRecord
    
    func record(params: [String: Any],  completion: @escaping (Result<RecordResponse, Error>) -> Void) {
        guard let url = URL(string: baseURL) else {
            return
        }
        guard  let accessToken = UserManager.shared.authToken else {
            
            print("No se pudo obtener el usuario o el token.")
            
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = params
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        } catch {
            print("linea 78 estamos revisando APIService")
            completion(.failure(error))
            return
        }
        print("Cambio en proceso \(request)")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error en la solicitud: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let data = data else {
                print("No se recibieron datos")
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            // Imprime el JSON recibido como cadena para inspección
            if let jsonString = String(data: data, encoding: .utf8) {
                print("JSON recibido: \(jsonString)")
            }

            do {
                let decodedResponse = try JSONDecoder().decode(RecordResponse.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                print("Error al decodificar: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }

        
        task.resume()
        
     
    }
    
   
}
