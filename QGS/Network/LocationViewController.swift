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
import SwiftUI


class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let locationManager: CLLocationManager = CLLocationManager()
    
    @Published var latitude: String = ""
    @Published var longitude: String = ""
    
    override init() {
        super.init()
        locationManager.delegate = self
                locationManager.requestWhenInUseAuthorization()
                locationManager.startUpdatingLocation()
        do{
            try  requestLocation()
        }catch{
            requestLocationPermission()
            print("Error: prueba")
        }
        
    }
    
    private func requestLocation()throws{
        
        // Validamos que este activo la localizacion
        guard CLLocationManager.locationServicesEnabled() else {
            
            return
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        requestLocationPermission()
        
    }
    
    func requestLocationPermission(){
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
    }
    
    func startBackgroundLocationUpdates(){
        locationManager.startUpdatingLocation()
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let bestLocation = locations.last else {
            print("si tenemos la mejor localizacion")
            return
        }
        latitude = String((bestLocation.coordinate.latitude))
        longitude = String((bestLocation.coordinate.longitude))
        manager.stopUpdatingLocation()
        print("Location updated.latitude: \(latitude) longitude: \(longitude)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
            print("Location authorization granted. ")
        case .denied, .restricted:
            
            manager.requestWhenInUseAuthorization()
            print("Location authorization denied. ")
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            print("Location authorization not determined.")
        @unknown default:
            
            print("Estado en autorizacion deconocido ")
        }
      //  requestLocationPermission()
        print("Location authorization status changed. ")
    }
}
