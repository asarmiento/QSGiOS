//
//  NetworkListDetails.swift
//  QGS
//
//  Created by Anwar Sarmiento on 12/2/24.
//

/**
 Lista de registro consulta a APIREST
 */
import Foundation
import Combine

struct ApiResponse: Codable {
    let data: [WorkEntry] // Aquí se espera que 'data' contenga el array de WorkEntry
}

class NetworkListDetails: ObservableObject {
    @Published var workEntries = [WorkEntry]()
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    private var cancellables = Set<AnyCancellable>()
   
    func fetchWorkEntries() {
        let id: String = {
               if let storedId = UserDefaults.standard.string(forKey: "employeeId") {
                   return storedId
               } else {
                   return "" // O maneja un valor por defecto
               }
           }()
        let token: String = {
               if let storedToken = UserDefaults.standard.string(forKey: "accessToken") {
                   return storedToken
               } else {
                   return "" // O maneja un valor por defecto
               }
           }()
        guard let url = URL(string: "\(Endpoints.getListDetail)\(id)") else {
            self.errorMessage = "URL no válida"
            return
        }
        print("Paso la url ")
        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
                   if let error = error {
                       DispatchQueue.main.async {
                           self.errorMessage = error.localizedDescription
                       }
                       print("Error: \(error.localizedDescription)")
                       return
                   }
                   
                   guard let data = data else {
                       DispatchQueue.main.async {
                           self.errorMessage = "No se recibieron datos"
                       }
                       return
                   }
                   
                   // Intentamos convertir los datos a un string para ver qué estamos recibiendo
                   if let jsonString = String(data: data, encoding: .utf8) {
                       print("Respuesta de la API: \(jsonString)") // Imprime la respuesta completa
                   }
                   
                   // Comprobamos si hay un mensaje de error en la respuesta (e.g., "Too Many Attempts")
                   if let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 429 {
                       DispatchQueue.main.async {
                           self.errorMessage = "Demasiados intentos. Por favor, intenta más tarde."
                       }
                       print("Error: Too Many Attempts")
                       return
                   }
                   
                   // Intentamos decodificar el JSON en un arreglo de WorkEntry
                   do {
                       // Decodificamos directamente el arreglo de WorkEntry
                       let decoder = JSONDecoder()
                       let workEntries = try decoder.decode([WorkEntry].self, from: data)
                       
                       DispatchQueue.main.async {
                           self.workEntries = workEntries // Asignamos los datos a la propiedad workEntries
                           self.errorMessage = nil // Limpiamos el mensaje de error
                       }
                       
                       print(workEntries) // Imprime el arreglo de WorkEntry
                   } catch {
                       DispatchQueue.main.async {
                           self.errorMessage = "Error al decodificar el JSON: \(error.localizedDescription)"
                       }
                       print("Error al decodificar el JSON: \(error)")
                   }
               }.resume()
    }
}


