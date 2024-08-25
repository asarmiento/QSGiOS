//
//  LocationViewController.swift
//  QGS
//
//  Created by Edin Martinez on 7/31/24.
//

import Foundation
import CoreLocation
import MapKit



class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    
    @Published var latitude: String?
    @Published var longitude: String?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
//        if CLLocationManager.headingAvailable(){
//            locationManager.delegate = self
//            locationManager.requestWhenInUseAuthorization()
//            locationManager.startUpdatingLocation()
//        }else{
//            locationManager.requestWhenInUseAuthorization()
//            locationManager.startUpdatingLocation()
//            print("no esta dando permiso")
//        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            latitude = String(format: "%.6f", location.coordinate.latitude)
            longitude = String(format: "%.6f", location.coordinate.longitude)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}
