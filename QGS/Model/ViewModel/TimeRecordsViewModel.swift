import Foundation
import Combine

class TimeRecordsViewModel: ObservableObject {
    @Published var timeRecords: [TimeRecord] = []
    @Published var filteredRecords: [TimeRecord] = []
    @Published var employees: [EmployeeCodable] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func fetchTimeRecords() {
        isLoading = true
        errorMessage = nil
        
        guard let token = UserManager.shared.authToken else {
            self.errorMessage = "No hay token de autenticación"
            self.isLoading = false
            return
        }
        
        let url = URL(string: "https://api.friendlypayroll.net/api/colaboradores/time-records")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [TimeRecord].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = "Error: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] records in
                self?.timeRecords = records
                self?.filteredRecords = records  // Inicialmente, mostrar todos los registros
            })
            .store(in: &cancellables)
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
    
    // Método para aplicar todos los filtros
    func applyFilters(employeeId: Int?, dates: Set<DateComponents>, type: String) {
        var filtered = timeRecords
        
        // Filtrar por empleado
        if let employeeId = employeeId {
            filtered = filtered.filter { $0.employee.id == employeeId }
        }
        
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
    
    // Método para limpiar todos los filtros
    func clearFilters() {
        DispatchQueue.main.async {
            self.filteredRecords = self.timeRecords
        }
    }
    
    // Método auxiliar para convertir string de fecha a Date
    private func dateFromString(_ dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.date(from: dateString)
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
} 