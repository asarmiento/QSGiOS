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
      
    @Published var latitude: Double = 0
    @Published var longitude: Double = 0
    
    override init() {
       super.init()
        do{
          try  setupLocationManager()
        }catch{
            requestLocationPermission()
            print("Error: prueba")
        }
        
    }

    private func setupLocationManager()throws{
        
        guard CLLocationManager.locationServicesEnabled() else {
            
          
            requestLocationPermission()
            return
        }
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.distanceFilter = kCLDistanceFilterNone
  
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
        latitude = Double(bestLocation.coordinate.latitude)
        longitude = Double(bestLocation.coordinate.longitude)
       
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
           
            print("Location authorization granted. ")
        case .denied, .restricted:
           
            manager.requestWhenInUseAuthorization()
            print("Location authorization denied. ")
        case .notDetermined:
           
            print("Location authorization not determined.")
        @unknown default:
           
            print("Estado en autorizacion deconocido ")
        }
        requestLocationPermission()
        print("Location authorization status changed. ")
    }
}
////MARK: - CLLocationManagerDelegate
//extension LocationViewController: CLLocationManagerDelegate {
//    didUpda
//}
