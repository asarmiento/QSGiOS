import Foundation
import Combine

class TimeRecordsViewModel: ObservableObject {
    @Published var timeRecords: [TimeRecord] = []
    @Published var filteredRecords: [TimeRecord] = []
    @Published var employees: [EmployeeCodable] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var updateSuccess: Bool = false
    @Published var updateMessage: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    func fetchTimeRecords() {
        isLoading = true
        errorMessage = nil
        
        guard let token = UserManager.shared.authToken else {
            self.errorMessage = "No hay token de autenticación"
            self.isLoading = false
            return
        }
        
        let url = URL(string: "https://api.friendlypayroll.net/api/projects/list-time-works")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .tryMap { data -> [TimeRecord] in
                // Imprimir los datos recibidos para depuración
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Datos recibidos: \(jsonString.prefix(500))...") // Mostrar solo los primeros 500 caracteres
                }
                
                do {
                    let decoder = JSONDecoder()
                    return try decoder.decode([TimeRecord].self, from: data)
                } catch {
                    print("Error de decodificación: \(error)")
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("Clave no encontrada: \(key.stringValue), contexto: \(context.debugDescription)")
                        case .typeMismatch(let type, let context):
                            print("Tipo incorrecto: \(type), contexto: \(context.debugDescription)")
                        case .valueNotFound(let type, let context):
                            print("Valor no encontrado: \(type), contexto: \(context.debugDescription)")
                        case .dataCorrupted(let context):
                            print("Datos corruptos: \(context.debugDescription)")
                        @unknown default:
                            print("Error de decodificación desconocido")
                        }
                    }
                    throw error
                }
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = "Error: \(error.localizedDescription)"
                    print("Error en la solicitud: \(error)")
                }
            }, receiveValue: { [weak self] records in
                self?.timeRecords = records
                self?.filteredRecords = records  // Inicialmente, mostrar todos los registros
                print("Registros cargados: \(records.count)")
            })
            .store(in: &cancellables)
    }
    
    // Método para cargar datos detallados de un empleado específico
    func fetchEmployeeDetailRecords(employeeId: Int) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            guard let token = UserManager.shared.authToken else {
                DispatchQueue.main.async {
                    self.errorMessage = "No hay token de autenticación"
                    self.isLoading = false
                }
                return
            }
            
            let url = URL(string: "https://api.friendlypayroll.net/api/projects/detail-time-work-employees/\(employeeId)")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            if httpResponse.statusCode == 200 {
                // Imprimir los datos recibidos para depuración
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Datos detallados recibidos: \(jsonString.prefix(500))...") // Mostrar solo los primeros 500 caracteres
                }
                
                let decoder = JSONDecoder()
                let detailedRecords = try decoder.decode([TimeRecord].self, from: data)
                
                DispatchQueue.main.async {
                    // Actualizar los registros filtrados con los datos detallados
                    self.filteredRecords = detailedRecords
                    
                    // También actualizar los registros generales si es necesario
                    // Esto es útil si queremos mantener una caché de todos los registros detallados
                    for detailedRecord in detailedRecords {
                        if let index = self.timeRecords.firstIndex(where: { $0.id == detailedRecord.id }) {
                            self.timeRecords[index] = detailedRecord
                        } else {
                            // Si el registro no existe en la lista general, lo añadimos
                            self.timeRecords.append(detailedRecord)
                        }
                    }
                    
                    self.isLoading = false
                }
            } else {
                throw URLError(.badServerResponse)
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Error al cargar los registros detallados: \(error.localizedDescription)"
                self.isLoading = false
                print("Error al cargar registros detallados: \(error)")
            }
        }
    }
    
    func fetchEmployees() {
        guard let token = UserManager.shared.authToken else {
            return
        }
        
        let url = URL(string: "https://api.friendlypayroll.net/api/colaboradores/list-employees")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [EmployeeCodable].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error al cargar empleados: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] employees in
                self?.employees = employees
            })
            .store(in: &cancellables)
    }
    
    // Método para actualizar horas y observaciones de un registro
    func updateTimeRecord(id: Int, hours: Double, observation: String) async -> Bool {
        guard let token = UserManager.shared.authToken else {
            DispatchQueue.main.async {
                self.updateSuccess = false
                self.updateMessage = "No hay token de autenticación"
            }
            return false
        }
        
        let urlString = "https://api.friendlypayroll.net/api/projects/update-data-time-work/\(id)"
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.updateSuccess = false
                self.updateMessage = "URL inválida"
            }
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // Crear el cuerpo de la solicitud
        let parameters: [String: Any] = [
            "hours": hours,
            "observation": observation
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self.updateSuccess = false
                    self.updateMessage = "Respuesta inválida del servidor"
                }
                return false
            }
            
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                // Actualizar el registro localmente
                DispatchQueue.main.async {
                    if let index = self.timeRecords.firstIndex(where: { $0.id == id && $0.type == "Salida"}) {
                        var updatedRecord = self.timeRecords[index]
                        updatedRecord.hours = hours
                        updatedRecord.observation = observation
                        self.timeRecords[index] = updatedRecord
                        
                        // También actualizar en filteredRecords si existe
                        if let filteredIndex = self.filteredRecords.firstIndex(where: { $0.id == id && $0.type == "Salida" }) {
                            var updatedFilteredRecord = self.filteredRecords[filteredIndex]
                            updatedFilteredRecord.hours = hours
                            updatedFilteredRecord.observation = observation
                            self.filteredRecords[filteredIndex] = updatedFilteredRecord
                        }
                        
                        self.updateSuccess = true
                        self.updateMessage = "Registro actualizado correctamente"
                    }
                }
                return true
            } else {
                // Intentar decodificar el mensaje de error
                let errorMessage: String
                if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                   let message = errorResponse["message"] {
                    errorMessage = message
                } else if let responseString = String(data: data, encoding: .utf8) {
                    errorMessage = "Error del servidor: \(responseString)"
                } else {
                    errorMessage = "Error del servidor: Código \(httpResponse.statusCode)"
                }
                
                DispatchQueue.main.async {
                    self.updateSuccess = false
                    self.updateMessage = errorMessage
                }
                return false
            }
        } catch {
            DispatchQueue.main.async {
                self.updateSuccess = false
                self.updateMessage = "Error: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // Método para aplicar todos los filtros
    func applyFilters(employeeId: Int?, dates: Set<DateComponents>, type: String) {
        // Si se selecciona un empleado específico, cargar sus datos detallados
        if let employeeId = employeeId {
            Task {
                await fetchEmployeeDetailRecords(employeeId: employeeId)
                
                // Después de cargar los datos detallados, aplicar los filtros de fecha y tipo
                DispatchQueue.main.async {
                    self.applyDateAndTypeFilters(dates: dates, type: type)
                }
            }
        } else {
            // Si no hay empleado seleccionado, aplicar filtros normales
            var filtered = timeRecords
            
            // Filtrar por fechas seleccionadas
            if !dates.isEmpty {
                filtered = filtered.filter { record in
                    if let recordDate = dateFromString(record.date) {
                        // Convertir la fecha del registro a DateComponents para comparar
                        let calendar = Calendar.current
                        let recordComponents = calendar.dateComponents([.year, .month, .day], from: recordDate)
                        
                        // Verificar si alguna de las fechas seleccionadas coincide con la fecha del registro
                        return dates.contains { selectedComponents in
                            // Comparar solo año, mes y día
                            return selectedComponents.year == recordComponents.year &&
                                   selectedComponents.month == recordComponents.month &&
                                   selectedComponents.day == recordComponents.day
                        }
                    }
                    return false
                }
            }
            
            // Filtrar por tipo
            if type != "Todos" {
                filtered = filtered.filter { $0.type == type }
            }
            
            // Actualizar los registros filtrados
            DispatchQueue.main.async {
                self.filteredRecords = filtered
            }
        }
    }
    
    // Método auxiliar para aplicar filtros de fecha y tipo después de cargar datos detallados
    private func applyDateAndTypeFilters(dates: Set<DateComponents>, type: String) {
        var filtered = filteredRecords
        
        // Filtrar por fechas seleccionadas
        if !dates.isEmpty {
            filtered = filtered.filter { record in
                if let recordDate = dateFromString(record.date) {
                    // Convertir la fecha del registro a DateComponents para comparar
                    let calendar = Calendar.current
                    let recordComponents = calendar.dateComponents([.year, .month, .day], from: recordDate)
                    
                    // Verificar si alguna de las fechas seleccionadas coincide con la fecha del registro
                    return dates.contains { selectedComponents in
                        // Comparar solo año, mes y día
                        return selectedComponents.year == recordComponents.year &&
                               selectedComponents.month == recordComponents.month &&
                               selectedComponents.day == recordComponents.day
                    }
                }
                return false
            }
        }
        
        // Filtrar por tipo
        if type != "Todos" {
            filtered = filtered.filter { $0.type == type }
        }
        
        self.filteredRecords = filtered
    }
    
    // Método para limpiar todos los filtros
    func clearFilters() {
        DispatchQueue.main.async {
            self.filteredRecords = self.timeRecords
        }
    }
    
    // Método auxiliar para convertir string de fecha a Date
    private func dateFromString(_ dateString: String) -> Date? {
        // Primero intentamos con el formato dd/MM/yyyy (formato que viene del API)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        if let date = dateFormatter.date(from: dateString) {
            return date
        }
        
        // Si falla, intentamos con el formato yyyy-MM-dd (formato alternativo)
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: dateString) {
            return date
        }
        
        // Si ambos fallan, intentamos con el formato del sistema
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.date(from: dateString)
    }
    
    // Método para filtrar registros por múltiples fechas (para compatibilidad con código existente)
    func filteredRecordsMultipleDates(selectedEmployeeId: Int?, selectedDates: Set<DateComponents>, selectedType: String) -> [TimeRecord] {
        var filtered = timeRecords
        
        // Filtrar por empleado
        if let employeeId = selectedEmployeeId {
            filtered = filtered.filter { $0.employee.id == employeeId }
        }
        
        // Filtrar por fechas seleccionadas
        if !selectedDates.isEmpty {
            filtered = filtered.filter { record in
                if let recordDate = dateFromString(record.date) {
                    // Convertir la fecha del registro a DateComponents para comparar
                    let calendar = Calendar.current
                    let recordComponents = calendar.dateComponents([.year, .month, .day], from: recordDate)
                    
                    // Verificar si alguna de las fechas seleccionadas coincide con la fecha del registro
                    return selectedDates.contains { selectedComponents in
                        // Comparar solo año, mes y día
                        return selectedComponents.year == recordComponents.year &&
                               selectedComponents.month == recordComponents.month &&
                               selectedComponents.day == recordComponents.day
                    }
                }
                return false
            }
        }
        
        // Filtrar por tipo
        if selectedType != "Todos" {
            filtered = filtered.filter { $0.type == selectedType }
        }
        
        return filtered
    }
    
    // Método para crear un nuevo registro de tiempo
    func createTimeRecord(employeeId: Int, date: String, time: String, type: String, hours: Double?, observation: String) async -> Bool {
        DispatchQueue.main.async {
            self.updateSuccess = false
            self.updateMessage = ""
        }
        
        guard let token = UserManager.shared.authToken else {
            DispatchQueue.main.async {
                self.updateSuccess = false
                self.updateMessage = "No hay token de autenticación"
            }
            return false
        }
        
        let urlString = EndPoints.storeRecordAdmin
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.updateSuccess = false
                self.updateMessage = "URL inválida"
            }
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // Usar valores fijos para latitud y longitud temporalmente
        // En una implementación real, estos valores vendrían del servicio de ubicación
        let latitude: Double = 0.0
        let longitude: Double = 0.0
        
        // Crear el cuerpo de la solicitud
        var parameters: [String: Any] = [
            "employee_id": employeeId,
            "date": date,
            "time": time,
            "latitude": latitude,
            "longitude": longitude,
            "type": type,
            "observation": observation
        ]
        
        // Añadir horas solo si es un registro de salida y hay un valor
        if type == "Salida", let hours = hours {
            parameters["hours"] = hours
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self.updateSuccess = false
                    self.updateMessage = "Respuesta inválida del servidor"
                }
                return false
            }
            
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                // Registro creado exitosamente
                DispatchQueue.main.async {
                    self.updateSuccess = true
                    self.updateMessage = "Registro creado correctamente"
                }
                return true
            } else {
                // Intentar decodificar el mensaje de error
                let errorMessage: String
                if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                   let message = errorResponse["message"] {
                    errorMessage = message
                } else if let responseString = String(data: data, encoding: .utf8) {
                    errorMessage = "Error del servidor: \(responseString)"
                } else {
                    errorMessage = "Error del servidor: Código \(httpResponse.statusCode)"
                }
                
                DispatchQueue.main.async {
                    self.updateSuccess = false
                    self.updateMessage = errorMessage
                }
                return false
            }
        } catch {
            DispatchQueue.main.async {
                self.updateSuccess = false
                self.updateMessage = "Error: \(error.localizedDescription)"
            }
            return false
        }
    }
} 
