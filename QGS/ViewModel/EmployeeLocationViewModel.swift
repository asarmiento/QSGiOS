import Foundation
import MapKit
import CoreLocation
import SwiftUI

// ViewModel para manejar la lógica de la vista
class EmployeeLocationViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var employeeLocations: [EmployeeLocationData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 9.9281, longitude: -84.0907),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var mapCameraPosition: MapCameraPosition {
        .region(region)
    }
    
    private var searchCompleter = MKLocalSearchCompleter()
    var onSearchResultsUpdated: (([MKLocalSearchCompletion]) -> Void)?
    
    override init() {
        super.init()
    }
    
    func setupSearchCompleter() {
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
    }
    
    func searchLocation(_ query: String) {
        searchCompleter.queryFragment = query
    }
    
    func fetchEmployeeLocations() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // Verificar si hay un token de autenticación disponible
            guard let accessToken = UserManager.shared.getAuthToken, !accessToken.isEmpty else {
                throw NSError(domain: "Error de autenticación", code: 401, userInfo: [NSLocalizedDescriptionKey: "No hay un token de autenticación válido"])
            }
            
            // Crear la URL para la petición
            guard let url = URL(string: EndPoints.getLocationEmployees) else {
                throw NSError(domain: "URL inválida", code: 400, userInfo: nil)
            }
            
            // Crear la solicitud
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            print("Realizando petición a: \(url)")
            print("Headers: \(request.allHTTPHeaderFields ?? [:])")
            
            // Realizar la solicitud a la API
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "Error en la respuesta", code: 500, userInfo: nil)
            }
            
            print("Código de estado HTTP: \(httpResponse.statusCode)")
            
            // Verificar el código de estado HTTP
            guard (200...299).contains(httpResponse.statusCode) else {
                let responseBody = String(data: data, encoding: .utf8) ?? "No se pudo leer el cuerpo de la respuesta"
                print("Cuerpo de respuesta de error: \(responseBody)")
                throw NSError(domain: "Error del servidor", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Error del servidor: código \(httpResponse.statusCode)"])
            }
            
            // Imprimir respuesta para depuración
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Respuesta recibida: \(jsonString)")
            }
            
            // Decodificar la respuesta
            let locations = try JSONDecoder().decode([EmployeeLocation].self, from: data)
            
            // Convertir a EmployeeLocationData y actualizar la UI
            await MainActor.run {
                self.employeeLocations = locations.enumerated().map { index, location in
                    EmployeeLocationData(
                        id: String(index + 1),
                        employeeName: location.employeeName,
                        projectName: location.projectName,
                        entryTime: location.entryTime,
                        latitude: location.latitude,
                        longitude: location.longitude
                    )
                }
                
                // Centrar el mapa en la primera ubicación si hay alguna
                if let firstLocation = self.employeeLocations.first {
                    let latitude = Double(firstLocation.latitude) ?? 9.9281
                    let longitude = Double(firstLocation.longitude) ?? -84.0907
                    
                    self.region = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                }
                
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Error al cargar las ubicaciones: \(error.localizedDescription)"
                print("Error en fetchEmployeeLocations: \(error)")
            }
        }
    }
    
    // Implementación de los métodos del delegado MKLocalSearchCompleterDelegate
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.onSearchResultsUpdated?(completer.results)
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error en la búsqueda: \(error.localizedDescription)")
    }
}
