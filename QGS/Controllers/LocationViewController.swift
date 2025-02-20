class LocationViewController: NSObject, ObservableObject {
    static let shared = LocationViewController()
    
    @Published var isAuthorized = false
    var locationManager: CLLocationManager?
    
    override init() {
        super.init()
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        checkAuthorization()
    }
    
    func checkAuthorization() {
        let currentStatus: CLAuthorizationStatus
        
        if #available(iOS 14.0, *) {
            currentStatus = locationManager?.authorizationStatus ?? .notDetermined
        } else {
            currentStatus = CLLocationManager.authorizationStatus()
        }
        
        isAuthorized = currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways
    }
    
    func getAuthorizationStatus() -> CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locationManager?.authorizationStatus ?? .notDetermined
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }
    
    func requestLocationPermission() {
        locationManager?.requestWhenInUseAuthorization()
    }
}

extension LocationViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkAuthorization()
    }
    
    // Para compatibilidad con iOS 13 y anteriores
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkAuthorization()
    }
} 