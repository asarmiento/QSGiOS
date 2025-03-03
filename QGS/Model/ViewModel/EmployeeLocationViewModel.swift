import Foundation
import MapKit

class EmployeeLocationViewModel: ObservableObject {
    @Published var employeeLocations: [EmployeeLocation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.769484, longitude: -84.071002),
        span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
    )
    
    func fetchEmployeeLocations() async {
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
            
            let url = URL(string: "https://api.friendlypayroll.net/api/projects/employee-location-job")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            if httpResponse.statusCode == 200 {
                let locations = try JSONDecoder().decode([EmployeeLocation].self, from: data)
                
                DispatchQueue.main.async {
                    self.employeeLocations = locations
                    
                    // Actualizar la región del mapa si hay ubicaciones
                    if let firstLocation = locations.first {
                        self.region = MKCoordinateRegion(
                            center: firstLocation.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
                        )
                    }
                    
                    self.isLoading = false
                }
            } else {
                throw URLError(.badServerResponse)
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Error al cargar las ubicaciones: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
} 