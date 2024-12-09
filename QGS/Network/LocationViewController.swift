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


class LocationViewController: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationViewController()
    private let locationManager: CLLocationManager = CLLocationManager()
    private var cachedAddress: String?
    @Published var latitude: String = ""
    @Published var longitude: String = ""
    @Published var address: String = ""
    private var isProcessingRequest = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.distanceFilter = 50 // Actualiza cada 50 metros
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
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
        guard !isProcessingRequest, let  bestLocation = locations.last else {
            print("si tenemos la mejor localizacion")
            return
        }
        if let cachedAddress = cachedAddress {
               print("Usando dirección en caché: \(cachedAddress)")
               return
           }
        
        latitude = String((bestLocation.coordinate.latitude))
        longitude = String((bestLocation.coordinate.longitude))
        
        isProcessingRequest = true
        // Obtener dirección con CLGeocoder
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(bestLocation) { placemarks, error in
            defer { self.isProcessingRequest = false }
            
            if let error = error {
                print("Error al obtener la dirección: \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first else {
                print("No se encontraron placemarks.")
                return
            }
            
            guard let placemark = placemarks?.first else { return }
            // Formatear la dirección
            self.address = """
                       \(placemark.name ?? ""), \
                       \(placemark.locality ?? ""), \
                       \(placemark.administrativeArea ?? ""), \
                       \(placemark.country ?? "")
                       """
            self.cachedAddress = self.address
          //  print("Dirección obtenida: \(self.address)")
        }}
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
       // print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
          //  print("Location authorization granted. ")
        case .denied, .restricted:
            
            manager.requestWhenInUseAuthorization()
           // print("Location authorization denied. ")
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
          //  print("Location authorization not determined.")
        @unknown default:
            
            print("Estado en autorizacion deconocido ")
        }
        //  requestLocationPermission()
       // print("Location authorization status changed. ")
    }
}
