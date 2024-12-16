import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var lastLocation: CLLocation?
    @Published var isRequestingAuthorization = false
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        DispatchQueue.main.async {
            self.locationStatus = self.locationManager.authorizationStatus
        }
    }
    
    func requestLocationPermission() {
        guard CLLocationManager.locationServicesEnabled() else {
            handleError(.servicioDesactivado)
            return
        }
        
        let currentStatus = locationManager.authorizationStatus
        
        switch currentStatus {
        case .notDetermined:
            isRequestingAuthorization = true
            DispatchQueue.global(qos: .userInitiated).async {
                self.locationManager.requestWhenInUseAuthorization()
            }
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        case .denied, .restricted:
            handleError(.permisoDenegado)
        @unknown default:
            handleError(.errorDesconocido(nil))
        }
    }
    
    private func startUpdatingLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            handleError(.servicioDesactivado)
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            if self.locationManager.authorizationStatus == .authorizedWhenInUse ||
               self.locationManager.authorizationStatus == .authorizedAlways {
                self.locationManager.startUpdatingLocation()
            }
        }
    }
    
    private func stopUpdatingLocation() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.locationManager.stopUpdatingLocation()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.locationStatus = manager.authorizationStatus
            self.isRequestingAuthorization = false
            
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                if self.lastLocation == nil {
                    self.startUpdatingLocation()
                }
            case .denied, .restricted:
                self.stopUpdatingLocation()
                self.handleError(.permisoDenegado)
            case .notDetermined:
                break
            @unknown default:
                self.handleError(.errorDesconocido(nil))
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
              location.horizontalAccuracy >= 0 else {
            handleError(.ubicacionInvalida)
            return
        }
        
        let locationAge = -location.timestamp.timeIntervalSinceNow
        guard locationAge <= 60 else {
            return
        }
        
        DispatchQueue.main.async {
            self.lastLocation = location
            self.errorMessage = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                handleError(.permisoDenegado)
            case .locationUnknown:
                handleError(.ubicacionDesconocida)
            case .network:
                handleError(.errorRed)
            case .headingFailure:
                break
            default:
                handleError(.errorDesconocido(clError))
            }
        } else {
            handleError(.errorDesconocido(error))
        }
    }
    
    private func handleError(_ error: LocationError) {
        DispatchQueue.main.async {
            self.errorMessage = error.errorDescription
        }
    }
    
    deinit {
        stopUpdatingLocation()
    }
} 