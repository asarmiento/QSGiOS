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
    private var locationManager:CLLocationManager = CLLocationManager()
    
    @Published var latitude: Double  = 0.0
    @Published var longitude: Double = 0.0
    
    override init() {
        super.init()
        do{
            try setupLocationManager()
        } catch {
            requestLocationPermission()
            print("Error setting up location manager: \(error.localizedDescription)")
        }
    }
    private func setupLocationManager() throws {
        requestLocationPermission()
        guard CLLocationManager.locationServicesEnabled()  else {
            
            return
        }
       
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.distanceFilter = kCLDistanceFilterNone
        
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
    }
    
    func startBackgroundLocationUpdates() {
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let bestLocation = locations.last else {
            return print("No location data available")
        }
        latitude = Double(bestLocation.coordinate.latitude)
        longitude = Double( bestLocation.coordinate.longitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("**** Failed to find user's location: \(error.localizedDescription) *****")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("Location authorization status changed")
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            startBackgroundLocationUpdates()
            print("Tiene acceson a la localización")
        case .denied, .restricted:
            startBackgroundLocationUpdates()
            //  let url =  UIApplicationOpenNotificationSettingsURLString
            print("No tiene acceso a la localización")
        case .notDetermined:
            print("No se ha determinado el estado de la autorización")
        default:
            break
        }
    }
}
