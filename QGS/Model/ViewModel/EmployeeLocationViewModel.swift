

import Foundation
import MapKit
import CoreLocation
import SwiftUI



// ViewModel definido aquí para asegurar que esté disponible
@MainActor
class EmployeeLocationViewModel: ObservableObject {
    @Published var employeeLocations: [EmployeeLocation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.769484, longitude: -84.071002),
        span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
    )
    
    // Para iOS 17+, usa MapCameraPosition
    @available(iOS 17.0, *)
    var mapCameraPosition: MapCameraPosition {
        MapCameraPosition.region(region)
    }

    // Para iOS 16 o versiones anteriores, usa MKCoordinateRegion
    var mapCameraRegion: MKCoordinateRegion {
        region
    }
    
    func fetchEmployeeLocations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let token = UserManager.shared.authToken else {
                errorMessage = "No hay token de autenticación"
                isLoading = false
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
                self.employeeLocations = locations
                
                if let firstLocation = locations.first {
                    self.region = MKCoordinateRegion(
                        center: firstLocation.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
                    )
                    // No necesitamos actualizar mapPosition aquí, ya que ahora es una propiedad computada
                }
            } else {
                throw URLError(.badServerResponse)
            }
        } catch {
            errorMessage = "Error al cargar las ubicaciones: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
