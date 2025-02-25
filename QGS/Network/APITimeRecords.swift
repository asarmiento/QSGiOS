import Foundation
import SwiftData

@MainActor
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
                print("separado", records)
                DispatchQueue.main.async {
                    self.timeRecords = records
                   
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    func fetchTimeRecords() async throws -> [TimeRecord] {
        // Construir la URL con el endpoint correcto
        guard let accessToken = UserManager.shared.authToken else {
            // Manejar error: no hay token
            throw NetworkLocalizedError.unauthorized
        }
        
        let url = URL(string: "https://api.friendlypayroll.net/api/projects/list-time-works")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Cabeceras y token
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        // Hacer la llamada
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Error desconocido"
            throw NetworkLocalizedError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500, errorMessage)
        }
        
        // Decodificar el JSON
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
        guard let accessToken = UserManager.shared.authToken else {
            print("No se pudo obtener el usuario o el token. \(UserManager.shared.getUser())")
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
                    // Imprime lo que llega para confirmar que no está vacío
                 
                    
                    self.employees = employees
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func fetchEmployeesFromAPI() async throws -> [EmployeeCodable] {
        guard let accessToken = UserManager.shared.authToken else {
            throw NetworkError.unauthorized
        }
        
        let url = URL(string: "https://api.friendlypayroll.net/api/colaboradores/list-employees")! // Asegúrate de que esta URL sea correcta
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Error desconocido"
            throw NetworkError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([EmployeeCodable].self, from: data)
    }

    func someFunctionUsingEmployeeID(record: TimeRecord) {
        let id = record.employee_id
        print("El ID del empleado es: \(id)")
    }

    func filteredRecordsMultipleDates(
        selectedEmployeeId: Int?,
        selectedDates: Set<DateComponents>,
        selectedType: String
    ) -> [TimeRecord] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return timeRecords.filter { record in
            guard let recordDate = dateFormatter.date(from: record.date) else {
                return false
            }
            
            // Filtrar por empleado
            let employeeMatches = (selectedEmployeeId == nil || record.employee_id == selectedEmployeeId)
            
            // Filtrar por tipo (Entrada/Salida)
            let typeMatches = (selectedType.isEmpty || record.type == selectedType)
            
            // Si no se seleccionó ninguna fecha, mostrar todo
            if selectedDates.isEmpty {
                return employeeMatches && typeMatches
            } else {
                // Filtrar si coincide con las fechas en selectedDates
                let recordComponents = Calendar.current.dateComponents([.year, .month, .day], from: recordDate)
                let dateMatches = selectedDates.contains(recordComponents)
                return employeeMatches && typeMatches && dateMatches
            }
        }
    }
} 
