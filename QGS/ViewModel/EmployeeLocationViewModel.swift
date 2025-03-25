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
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulamos una carga de datos
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Datos de ejemplo
            let exampleLocations = [
                EmployeeLocationData(
                    id: "1",
                    employeeName: "Juan Pérez",
                    projectName: "Proyecto A",
                    entryTime: "08:30 AM",
                    latitude: "9.9281",
                    longitude: "-84.0907"
                ),
                EmployeeLocationData(
                    id: "2",
                    employeeName: "María López",
                    projectName: "Proyecto B",
                    entryTime: "09:15 AM",
                    latitude: "9.9350",
                    longitude: "-84.0850"
                ),
                EmployeeLocationData(
                    id: "3",
                    employeeName: "Carlos Rodríguez",
                    projectName: "Proyecto C",
                    entryTime: "08:45 AM",
                    latitude: "9.9200",
                    longitude: "-84.0950"
                )
            ]
            
            await MainActor.run {
                self.employeeLocations = exampleLocations
                
                // Centrar el mapa en la primera ubicación si hay alguna
                if let firstLocation = employeeLocations.first {
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
