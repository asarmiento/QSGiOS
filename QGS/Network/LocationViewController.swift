//
//  LocationViewController.swift
//  QGS
//
//  Created by Anwar Sarmiento on 7/31/24.
//
import Foundation
import CoreLocation
import SwiftUI

class LocationViewController: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationViewController()

    private let locationManager = CLLocationManager()
    private var cachedAddress: String?
    @Published var latitude: String = ""
    @Published var longitude: String = ""
    @Published var address: String = ""
    @Published var isAuthorized: Bool = false
    private var isProcessingRequest = false

    override init() {
        super.init()
        locationManager.delegate = self
        requestLocationPermission()
    }

    func requestLocationPermission() {
        guard CLLocationManager.locationServicesEnabled() else {
            print("Los servicios de ubicación están desactivados.")
            return
        }

        DispatchQueue.main.async {
            switch self.locationManager.authorizationStatus {
            case .notDetermined:
                self.locationManager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                self.startUpdatingLocation()
            case .denied, .restricted:
                self.isAuthorized = true
                print("Permiso denegado o restringido.")
            @unknown default:
                self.isAuthorized = true
                print("Estado de autorización desconocido.")
            }
        }
    }

    func startUpdatingLocation() {
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                self.locationManager.startUpdatingLocation()
            case .denied, .restricted:
                self.isAuthorized = true
                print("Permisos de ubicación denegados. Muestra alerta al usuario.")
                // Muestra una alerta para guiar al usuario a habilitar permisos.
            case .notDetermined:
                self.isAuthorized = true
                print("Esperando autorización de ubicación.")
            @unknown default:
                self.isAuthorized = true
                print("Estado desconocido.")
            }
        }
    }
    

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !isProcessingRequest, let bestLocation = locations.last else { return }

        latitude = String(bestLocation.coordinate.latitude)
        longitude = String(bestLocation.coordinate.longitude)

        isProcessingRequest = true
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(bestLocation) { placemarks, error in
            defer { self.isProcessingRequest = false }

            if let error = error {
                print("Error al obtener la dirección: \(error.localizedDescription)")
                return
            }

            if let placemark = placemarks?.first {
                self.address = """
                \(placemark.name ?? ""), \(placemark.locality ?? ""), \
                \(placemark.administrativeArea ?? ""), \(placemark.country ?? "")
                """
                self.cachedAddress = self.address
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error al obtener la ubicación: \(error.localizedDescription)")
    }
}
