import CoreLocation
import SwiftUI

public class LocationManager: NSObject, ObservableObject {
    public static let shared = LocationManager()
    
    @Published public var isAuthorized = false
    private var locationManager: CLLocationManager?
    
    override public init() {
        super.init()
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        checkAuthorization()
    }
    
    public func checkAuthorization() {
        let currentStatus = getAuthorizationStatus()
        isAuthorized = currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways
    }
    
    public func getAuthorizationStatus() -> CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locationManager?.authorizationStatus ?? .notDetermined
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }
    
    public func requestLocationPermission() {
        locationManager?.requestWhenInUseAuthorization()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkAuthorization()
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkAuthorization()
    }
} 