import Foundation
import SwiftData

@MainActor
class TimeRecordsViewModel: ObservableObject {
    @Published var timeRecords: [TimeRecord] = []
    @Published var employees: [EmployeeCodable] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var prevPageURL: String?
    @Published var nextPageURL: String?

    func fetchTimeRecords() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let records = try await fetchRecordsFromAPI()
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

    func fetchRecordsFromAPI() async throws -> [TimeRecord] {
        guard let accessToken = UserManager.shared.authToken else {
            throw NetworkError.unauthorized
        }
        
        let url = URL(string: "https://api.friendlypayroll.net/api/projects/list-time-works")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Error desconocido"
            throw NetworkError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        let decoder = JSONDecoder()
        let paginatedResponse = try decoder.decode(PaginadoResponse<TimeRecord>.self, from: data)
        
        self.timeRecords = paginatedResponse.data
        self.prevPageURL = paginatedResponse.prevPageURL
        self.nextPageURL = paginatedResponse.nextPageURL
        return paginatedResponse.data
    }

    func filteredRecords(selectedEmployeeId: Int?, selectedDate: Date, selectedType: String) -> [TimeRecord] {
        return timeRecords.filter { record in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let recordDate = dateFormatter.date(from: record.date) ?? Date()
            
            return (selectedEmployeeId == nil || record.employeeId == selectedEmployeeId) &&
                   Calendar.current.isDate(recordDate, inSameDayAs: selectedDate) &&
                   (record.type == selectedType || selectedType.isEmpty)
        }
    }

    func loadPage(url: String) {
        Task {
            do {
                let records = try await fetchRecordsFromAPI(url: url)
                DispatchQueue.main.async {
                    self.timeRecords = records
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func fetchRecordsFromAPI(url: String) async throws -> [TimeRecord] {
        guard let accessToken = UserManager.shared.authToken else {
            print("No se pudo obtener el usuario o el token.")
            throw NetworkError.unauthorized
        }
        
        var request = URLRequest(url: URL(string: url)!)
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
        let paginatedResponse = try decoder.decode(PaginadoResponse<TimeRecord>.self, from: data)
        
        // Actualiza la URL de la página anterior y siguiente
        self.prevPageURL = paginatedResponse.prevPageURL
        self.nextPageURL = paginatedResponse.nextPageURL
        
        return paginatedResponse.data
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
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func fetchEmployeesFromAPI() async throws -> [EmployeeCodable] {
        guard let accessToken = UserManager.shared.authToken else {
            throw NetworkError.unauthorized
        }
        
        let url = URL(string: "https://api.friendlypayroll.net/api/projects/list-employees")! // Asegúrate de que esta URL sea correcta
        
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
} 
