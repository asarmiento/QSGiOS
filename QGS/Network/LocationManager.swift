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
        
        // En lugar de verificar inmediatamente, espera el callback
        DispatchQueue.global().async {
            self.locationManager.delegate = self
        }
    }
    
    /// Revisa si está autorizado y, si no, prepara la solicitud.
    public func checkAuthorizationStatus() {
        DispatchQueue.global().async {
            let status = self.locationManager.authorizationStatus
            // Si no está determinado, solicitamos el permiso más adelante.
            if status == .notDetermined && !self.statusChecked {
                // Marcamos que ya preguntamos en esta sesión
                self.statusChecked = true
                // Hacemos la solicitud en segundo plano para evitar bloqueo en la UI
                self.locationManager.requestWhenInUseAuthorization()
            }
        }
    }
    
    public func startUpdatingLocation() {
        DispatchQueue.global().async {
            // Inicia la actualización de ubicación
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
                self.isAuthorized =
                    manager.authorizationStatus == .authorizedWhenInUse ||
                    manager.authorizationStatus == .authorizedAlways
            } else {
                self.locationStatus = CLLocationManager.authorizationStatus()
                self.isAuthorized =
                    CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
                    CLLocationManager.authorizationStatus() == .authorizedAlways
            }
            
            // Si detectamos que no estamos autorizados pero tampoco lo hemos pedido, lo solicitamos
            if !self.isAuthorized && !self.statusChecked {
                self.checkAuthorizationStatus()
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager,
                                didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.lastLocation = location
        }
    }
    
    public func locationManager(_ manager: CLLocationManager,
                                didFailWithError error: Error) {
        print("Error de ubicación: \(error.localizedDescription)")
    }
} 

