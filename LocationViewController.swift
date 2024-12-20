import CoreLocation
import SwiftUI

class LocationViewController: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationViewController()
    private let locationManager = CLLocationManager()
    
    @Published var latitude: String = ""
    @Published var longitude: String = ""
    @Published var address: String = ""
    @Published var isAuthorized: Bool = false
    @Published var locationError: String?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        checkLocationServices()
    }
    
    private func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
        } else {
            locationError = "Los servicios de localización están desactivados"
        }
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationPermission() {
        DispatchQueue.global(qos: .userInitiated).async {
            if CLLocationManager.locationServicesEnabled() {
                DispatchQueue.main.async {
                    self.locationManager.requestWhenInUseAuthorization()
                }
            } else {
                DispatchQueue.main.async {
                    self.locationError = "Los servicios de localización están desactivados"
                }
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.isAuthorized = true
                self.locationManager.startUpdatingLocation()
            case .denied, .restricted:
                self.isAuthorized = false
                self.locationError = "Acceso a la ubicación denegado"
            case .notDetermined:
                self.isAuthorized = false
            @unknown default:
                break
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.latitude = String(format: "%.6f", location.coordinate.latitude)
            self.longitude = String(format: "%.6f", location.coordinate.longitude)
            self.locationError = nil
            
            // Obtener dirección
            self.getAddressFromLocation(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.locationError = "Acceso a la ubicación denegado"
                case .locationUnknown:
                    self.locationError = "No se puede determinar la ubicación"
                default:
                    self.locationError = "Error al obtener la ubicación: \(error.localizedDescription)"
                }
            } else {
                self.locationError = "Error al obtener la ubicación: \(error.localizedDescription)"
            }
        }
    }
    
    private func getAddressFromLocation(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self?.locationError = "Error al obtener la dirección: \(error.localizedDescription)"
                    return
                }
                
                if let placemark = placemarks?.first {
                    let address = [
                        placemark.subThoroughfare,
                        placemark.thoroughfare,
                        placemark.locality,
                        placemark.administrativeArea,
                        placemark.country
                    ].compactMap { $0 }.joined(separator: ", ")
                    
                    self?.address = address
                }
            }
        }
    }
} 