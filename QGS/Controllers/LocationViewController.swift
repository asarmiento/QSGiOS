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
    
    func checkAuthorizationStatus() {
        checkAuthorization()
    }
    
    func startUpdatingLocation() {
        // Verificar si tenemos permiso para acceder a la ubicación
        if isAuthorized {
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            locationManager?.distanceFilter = 10 // Actualizar cada 10 metros
            locationManager?.startUpdatingLocation()
            print("Iniciando actualización de ubicación")
        } else {
            print("No hay autorización para acceder a la ubicación")
            requestLocationPermission()
        }
    }
    
    func stopUpdatingLocation() {
        locationManager?.stopUpdatingLocation()
        print("Deteniendo actualización de ubicación")
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
    
    // Implementar el método para recibir actualizaciones de ubicación
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            print("Ubicación actualizada: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }
    
    // Implementar el método para manejar errores de ubicación
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error al obtener la ubicación: \(error.localizedDescription)")
    }
} 