import Foundation
import SwiftData

@MainActor
/*
 class TimeRecordsViewModel: ObservableObject {
     @Published var timeRecords: [TimeRecord] = []
     @Published var employees: [EmployeeCodable] = []
     @Published var isLoading = false
     @Published var errorMessage: String?

     func fetchTimeRecords() {
         isLoading = true
         errorMessage = nil
         
         Task {
             do {
                 let records = try await fetchTimeRecords()
                 DispatchQueue.main.async {
                     self.timeRecords = records
                     self.isLoading = false
                 }
             } catch {
                 handleError(error)
             }
         }
     }

     func fetchTimeRecords() async throws -> [TimeRecord] {
         guard let accessToken = UserManager.shared.getAuthToken else {
             throw NetworkLocalizedError.unauthorized
         }
         
         let url = URL(string: "https://api.friendlypayroll.net/api/projects/list-time-works")!
         
         var request = URLRequest(url: url)
         request.httpMethod = "GET"
         request.setValue("application/json", forHTTPHeaderField: "Accept")
         request.setValue("application/json", forHTTPHeaderField: "Content-Type")
         request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
         
         let (data, response) = try await URLSession.shared.data(for: request)
         
         guard let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) else {
             let errorMessage = String(data: data, encoding: .utf8) ?? "Error desconocido"
             let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
             throw NetworkLocalizedError.serverError(statusCode, errorMessage)
         }
         
         let decoder = JSONDecoder()
         return try decoder.decode([TimeRecord].self, from: data)
     }

     func filteredRecords(selectedEmployeeId: Int?, selectedDate: Date, selectedType: String) -> [TimeRecord] {
         // Formato de fecha del backend (yyyy-MM-dd)
         let dateFormatter = DateFormatter()
         dateFormatter.dateFormat = "yyyy-MM-dd"
         
         return timeRecords.filter { record in
             guard let recordDate = dateFormatter.date(from: record.date) else {
                 // Si la fecha del JSON no puede convertirse, descartar el registro
                 return false
             }
             
             // Coincidir empleado (si es nil, aceptar cualquiera)
             let employeeMatches = (selectedEmployeeId == nil || record.employee_id == selectedEmployeeId)
             
             // Coincidir tipo (Entrada/Salida). Si selectedType está vacío, admite ambos.
             let typeMatches = (selectedType.isEmpty || record.type == selectedType)
             
             let dateMatches = Calendar.current.isDate(recordDate, inSameDayAs: selectedDate)
             return employeeMatches && dateMatches && typeMatches
         }
     }

     func loadPage(url: String) {
         Task {
             do {
                 let records = try await fetchTimeRecords()
                 DispatchQueue.main.async {
                        print("registros DESCARGADOS:", records)
                     self.timeRecords = records
                 }
             } catch {
                 DispatchQueue.main.async {
                     self.errorMessage = error.localizedDescription
                 }
             }
         }
     }

     func fetchRecordsFromAPI() async throws -> [TimeRecord] {
         let url = "https://api.friendlypayroll.net/api/projects/list-time-works"
         guard let accessToken = UserManager.shared.getAuthToken else {
           //  print("No se pudo obtener el usuario o el token. \(UserManager.shared.getUser())")
             throw NetworkError.unauthorized
         //return Login()
         }
         
         var request = URLRequest(url: URL(string: url)!)
         request.httpMethod = "GET"
         request.addValue("application/json", forHTTPHeaderField: "Content-Type")
         request.addValue("application/json", forHTTPHeaderField: "Accept")
         request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
         
         let (data, response) = try await URLSession.shared.data(for: request)
         
         guard let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) else {
             let errorMessage = String(data: data, encoding: .utf8) ?? "Error desconocido"
             throw NetworkError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500, errorMessage)
         }
         
         let decoder = JSONDecoder()
         return try decoder.decode([TimeRecord].self, from: data)
     }

     func fetchEmployees() {
         Task {
             do {
                 let employees = try await fetchEmployeesFromAPI()
                 DispatchQueue.main.async {
                     self.employees = employees
                 }
             } catch {
                 DispatchQueue.main.async {
                     // Manejo seguro del mensaje de error
                     self.errorMessage = error.localizedDescription
                 }
             }
         }
     }

     func fetchEmployeesFromAPI() async throws -> [EmployeeCodable] {
         guard let accessToken = UserManager.shared.getAuthToken else {
             throw NetworkLocalizedError.unauthorized
         }
         
         let url = URL(string: "https://api.friendlypayroll.net/api/colaboradores/list-employees")!
         
         var request = URLRequest(url: url)
         request.httpMethod = "GET"
         request.setValue("application/json", forHTTPHeaderField: "Content-Type")
         request.setValue("application/json", forHTTPHeaderField: "Accept")
         request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
         
         let (data, response) = try await URLSession.shared.data(for: request)
         
         guard let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) else {
             let errorMessage = String(data: data, encoding: .utf8) ?? "Error desconocido"
             let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
             throw NetworkLocalizedError.serverError(statusCode, errorMessage)
         }
         
         let decoder = JSONDecoder()
         return try decoder.decode([EmployeeCodable].self, from: data)
     }

     func someFunctionUsingEmployeeID(record: TimeRecord) {
         // Asumiendo que employee_id es un Int no opcional en TimeRecord
         print("El ID del empleado es: \(record.employee_id)")
     }

     func filteredRecordsMultipleDates(
         selectedEmployeeId: Int?,
         selectedDates: Set<DateComponents>,
         selectedType: String
     ) -> [TimeRecord] {
         timeRecords.filter { record in
             // Filtrar por empleado
             let employeeMatches = selectedEmployeeId == nil || record.employee_id == selectedEmployeeId
             
             // Filtrar por tipo
             let typeMatches = selectedType.isEmpty || record.type == selectedType
             
             // Filtrar por fechas
             let dateFormatter = DateFormatter()
             dateFormatter.dateFormat = "yyyy-MM-dd"
             
             let dateMatches: Bool
             if selectedDates.isEmpty {
                 dateMatches = true
             } else if let recordDate = dateFormatter.date(from: record.date) {
                 let components = Calendar.current.dateComponents([.year, .month, .day], from: recordDate)
                 dateMatches = selectedDates.contains(components)
             } else {
                 dateMatches = false
             }
             
             return employeeMatches && typeMatches && dateMatches
         }
     }

     private func handleError(_ error: Error) {
         DispatchQueue.main.async {
             self.errorMessage = error.localizedDescription
             self.isLoading = false
         }
     }
 }

 */
// Estructura para manejar respuestas de error
struct ErrorResponse: Codable {
    let message: String
}

enum APIErrorRecord: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case notFound
    case serverError(Int, String)
    case networkError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case .unauthorized:
            return "No autorizado"
        case .notFound:
            return "Recurso no encontrado"
        case .serverError(let code, let message):
            return "Error del servidor (\(code)): \(message)"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Error al procesar datos: \(error.localizedDescription)"
        }
    }
} 
