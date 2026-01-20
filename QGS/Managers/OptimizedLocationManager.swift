import CoreLocation
import SwiftUI

// MARK: - Performance Optimized Location Manager
/// Enhanced location manager with adaptive accuracy and battery optimization
public class OptimizedLocationManager: NSObject, ObservableObject {
    public static let shared = OptimizedLocationManager()
    
    @Published public var locationStatus: CLAuthorizationStatus?
    @Published public var lastLocation: CLLocation?
    @Published public var isAuthorized = false
    @Published public var currentAddress = ""
    
    private var locationManager: CLLocationManager
    private var statusChecked = false
    private var isHighAccuracyNeeded = false
    private var currentAccuracy: CLLocationAccuracy = kCLLocationAccuracyHundredMeters
    private var locationUpdateTimer: Timer?
    private var activeGeocodingTask: Task<Void, Never>?
    
    // MARK: - Performance Optimization Properties
    private let addressCache = NSCache<NSString, NSString>()
    private var lastGeocodingLocation: CLLocation?
    private let minimumDistanceForGeocoding: CLLocationDistance = 100 // meters
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        
        setupLocationManager()
        setupAddressCache()
        checkAuthorizationStatus()
        
        logInfo("OptimizedLocationManager initialized", category: .location)
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Setup Methods
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = currentAccuracy
        locationManager.distanceFilter = 50 // Larger filter to reduce updates
    }
    
    private func setupAddressCache() {
        addressCache.countLimit = 50
        addressCache.totalCostLimit = 5 * 1024 * 1024 // 5MB
    }
    
    // MARK: - Public Methods
    public func checkAuthorizationStatus() {
        Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }
            
            let status = self.locationManager.authorizationStatus
            
            await MainActor.run {
                self.locationStatus = status
                self.isAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways
            }
            
            if status == .notDetermined && !self.statusChecked {
                self.statusChecked = true
                await MainActor.run {
                    self.locationManager.requestWhenInUseAuthorization()
                }
            }
            
            logDebug("Location authorization status: \(status.rawValue)", category: .location)
        }
    }
    
    public func requestLocationPermission() {
        Task.detached(priority: .utility) { [weak self] in
            await MainActor.run {
                self?.locationManager.requestWhenInUseAuthorization()
            }
        }
    }
    
    public func startUpdatingLocation() {
        Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }
            
            await MainActor.run {
                // Use appropriate accuracy based on use case
                self.locationManager.desiredAccuracy = self.isHighAccuracyNeeded ? 
                    kCLLocationAccuracyBest : kCLLocationAccuracyHundredMeters
                
                // Larger distance filter to reduce updates
                self.locationManager.distanceFilter = self.isHighAccuracyNeeded ? 5 : 50
                
                self.locationManager.startUpdatingLocation()
                logInfo("Started location updates with accuracy: \(self.currentAccuracy)", category: .location)
            }
            
            // Auto-stop after getting good location (if not high accuracy mode)
            if !self.isHighAccuracyNeeded {
                try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                if !Task.isCancelled {
                    await MainActor.run {
                        self.stopUpdatingLocation()
                    }
                }
            }
        }
    }
    
    public func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
        
        logInfo("Stopped location updates", category: .location)
    }
    
    // MARK: - High Accuracy Mode for Time Recording
    public func requestHighAccuracyLocation() {
        isHighAccuracyNeeded = true
        currentAccuracy = kCLLocationAccuracyBest
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            await MainActor.run {
                self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
                self.locationManager.distanceFilter = 5
                self.startUpdatingLocation()
            }
            
            logInfo("High accuracy location requested", category: .location)
            
            // Auto-stop high accuracy after 30 seconds to save battery
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            if !Task.isCancelled {
                await MainActor.run {
                    self.isHighAccuracyNeeded = false
                    self.currentAccuracy = kCLLocationAccuracyHundredMeters
                    self.stopUpdatingLocation()
                }
            }
        }
    }
    
    // MARK: - Address Geocoding with Caching
    public func getCurrentAddress() async -> String {
        guard let location = lastLocation else {
            logWarning("No location available for address lookup", category: .location)
            return currentAddress
        }
        
        // Check if we need to update address (moved significantly)
        if let lastGeocodingLocation = lastGeocodingLocation,
           location.distance(from: lastGeocodingLocation) < minimumDistanceForGeocoding {
            return currentAddress
        }
        
        // Check cache first
        let cacheKey = "\(location.coordinate.latitude),\(location.coordinate.longitude)" as NSString
        if let cachedAddress = addressCache.object(forKey: cacheKey) as String? {
            return cachedAddress
        }
        
        // Cancel previous geocoding task
        activeGeocodingTask?.cancel()
        
        return await withCheckedContinuation { continuation in
            activeGeocodingTask = Task { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: self?.currentAddress ?? "")
                    return
                }
                
                do {
                    let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
                    
                    if !Task.isCancelled, let placemark = placemarks.first {
                        let address = self.formatAddress(from: placemark)
                        
                        await MainActor.run {
                            self.currentAddress = address
                            self.lastGeocodingLocation = location
                            
                            // Cache the result
                            self.addressCache.setObject(address as NSString, forKey: cacheKey)
                        }
                        
                        logDebug("Address geocoded successfully", category: .location, metadata: [
                            "address": address,
                            "coordinates": "\(location.coordinate.latitude),\(location.coordinate.longitude)"
                        ])
                        
                        continuation.resume(returning: address)
                    } else {
                        continuation.resume(returning: self.currentAddress)
                    }
                } catch {
                    if !Task.isCancelled {
                        logError("Geocoding failed", category: .location, metadata: [
                            "error": error.localizedDescription
                        ])
                    }
                    continuation.resume(returning: self.currentAddress)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func formatAddress(from placemark: CLPlacemark) -> String {
        let components = [
            placemark.name,
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country
        ].compactMap { $0 }
        
        return components.joined(separator: ", ")
    }
    
    private func cleanup() {
        locationUpdateTimer?.invalidate()
        activeGeocodingTask?.cancel()
        stopUpdatingLocation()
        
        logInfo("OptimizedLocationManager cleaned up", category: .location)
    }
    
    // MARK: - Location Validation
    private func isLocationValid(_ location: CLLocation) -> Bool {
        let age = abs(location.timestamp.timeIntervalSinceNow)
        return age < 30 && // Location is recent (less than 30 seconds old)
               location.horizontalAccuracy > 0 && // Valid accuracy
               location.horizontalAccuracy < 100 // Reasonable accuracy (less than 100 meters)
    }
}

// MARK: - CLLocationManagerDelegate
extension OptimizedLocationManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let bestLocation = locations.last,
              isLocationValid(bestLocation) else {
            logWarning("Received invalid location update", category: .location)
            return
        }
        
        lastLocation = bestLocation
        
        logDebug("Location updated", category: .location, metadata: [
            "latitude": bestLocation.coordinate.latitude,
            "longitude": bestLocation.coordinate.longitude,
            "accuracy": bestLocation.horizontalAccuracy
        ])
        
        // Update address in background if needed
        Task.detached(priority: .background) { [weak self] in
            let _ = await self?.getCurrentAddress()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logError("Location manager failed", category: .location, metadata: [
            "error": error.localizedDescription
        ])
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            locationStatus = status
            isAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways
            
            logInfo("Location authorization changed", category: .location, metadata: [
                "status": status.rawValue,
                "authorized": isAuthorized
            ])
            
            if isAuthorized {
                startUpdatingLocation()
            } else {
                stopUpdatingLocation()
            }
        }
    }
}

// MARK: - Location Extensions for Performance
extension CLAuthorizationStatus {
    var isAuthorized: Bool {
        return self == .authorizedWhenInUse || self == .authorizedAlways
    }
    
    var localizedDescription: String {
        switch self {
        case .notDetermined:
            return "No determinado"
        case .restricted:
            return "Restringido"
        case .denied:
            return "Denegado"
        case .authorizedAlways:
            return "Autorizado siempre"
        case .authorizedWhenInUse:
            return "Autorizado en uso"
        @unknown default:
            return "Desconocido"
        }
    }
}