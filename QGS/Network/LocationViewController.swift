//
//  LocationViewController.swift
//  QGS
//
//  Created by Edin Martinez on 7/31/24.
//

import Foundation
import CoreLocation
import CoreLocationUI
import MapKit



class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager?
    private var userLocation: CLLocation?
     
    @Published var latitude: Double = 0
    @Published var longitude: Double = 0
    
    override init() {
       super.init()
        requestLocation()
        
    }
    private func requestLocation(){
       
            guard CLLocationManager.locationServicesEnabled() else {
                return
            }
            
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            locationManager?.requestAlwaysAuthorization()
            locationManager?.startUpdatingLocation()
        
        switch self.locationManager?.authorizationStatus { // check authorizationStatus instead of locationServicesEnabled()
                case .notDetermined, .authorizedWhenInUse:
                    self.locationManager?.requestAlwaysAuthorization()
                case .restricted, .denied:
                    print("ALERT: no location services access")
            case .authorizedAlways:
                break
            case .none, .some(_):
                break
            }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let bestLocation = locations.last else {
            return
        }
        latitude = Double(bestLocation.coordinate.latitude)
        longitude = Double(bestLocation.coordinate.longitude)
       
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}
////MARK: - CLLocationManagerDelegate
//extension LocationViewController: CLLocationManagerDelegate {
//    didUpda
//}
