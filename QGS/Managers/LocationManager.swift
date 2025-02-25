import CoreLocation
import SwiftUI

public class LocationManager: NSObject, ObservableObject {
    public static let shared = LocationManager()
    
    @Published public var locationStatus: CLAuthorizationStatus?
    @Published public var lastLocation: CLLocation?
    @Published public var isAuthorized = false
    
    private var locationManager: CLLocationManager
    private var statusChecked = false
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        
        // Solicitar permisos de ubicación
        checkAuthorizationStatus()
    }
    
    public func checkAuthorizationStatus() {
        DispatchQueue.global().async {
            let status = self.locationManager.authorizationStatus
            if status == .notDetermined && !self.statusChecked {
                self.statusChecked = true
                self.locationManager.requestWhenInUseAuthorization()
            }
        }
    }
    
    public func getAuthorizationStatus() -> CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }
    
    public func requestLocationPermission() {
        DispatchQueue.global().async {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    public func startUpdatingLocation() {
        DispatchQueue.global().async {
            self.locationManager.startUpdatingLocation()
        }
    }
    
    public func stopUpdatingLocation() {
        DispatchQueue.global().async {
            self.locationManager.stopUpdatingLocation()
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            if #available(iOS 14.0, *) {
                self.locationStatus = manager.authorizationStatus
                self.isAuthorized = manager.authorizationStatus == .authorizedWhenInUse ||
                                  manager.authorizationStatus == .authorizedAlways
            } else {
                self.locationStatus = CLLocationManager.authorizationStatus()
                self.isAuthorized = CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
                                  CLLocationManager.authorizationStatus() == .authorizedAlways
            }
            
            // Si es la primera verificación y no está autorizado, solicitar permiso
            if !self.statusChecked && !self.isAuthorized {
                self.requestLocationPermission()
                self.statusChecked = true
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.lastLocation = location
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error de ubicación: \(error.localizedDescription)")
    }
}

// Extensión para acceder fácilmente a las coordenadas
extension LocationManager {
    public var latitude: String {
        return "\(lastLocation?.coordinate.latitude ?? 0)"
    }
    
    public var longitude: String {
        return "\(lastLocation?.coordinate.longitude ?? 0)"
    }
    
    public var locationCoordinate: CLLocationCoordinate2D? {
        return lastLocation?.coordinate
    }
} 