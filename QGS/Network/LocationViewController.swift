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
    @Published var isRequestingAuthorization: Bool = false
    private var isProcessingRequest = false

    override init() {
        super.init()
        locationManager.delegate = self
        checkLocationAuthorization()
    }

    private func checkLocationAuthorization() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let status = self.locationManager.authorizationStatus
            DispatchQueue.main.async {
                self.handleAuthorizationStatus(status)
            }
        }
    }

    func requestLocationPermission() {
        guard !isRequestingAuthorization else { return }
        
        isRequestingAuthorization = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if CLLocationManager.locationServicesEnabled() {
                let status = self.locationManager.authorizationStatus
                DispatchQueue.main.async {
                    switch status {
                    case .notDetermined:
                        self.locationManager.requestWhenInUseAuthorization()
                    case .authorizedWhenInUse, .authorizedAlways:
                        self.startUpdatingLocation()
                    case .denied, .restricted:
                        self.isAuthorized = false
                        print("Permiso denegado o restringido.")
                    @unknown default:
                        self.isAuthorized = false
                        print("Estado de autorización desconocido.")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isAuthorized = false
                    print("Servicios de localización desactivados")
                }
            }
        }
    }

    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
            startUpdatingLocation()
        case .denied, .restricted:
            isAuthorized = false
            print("Permisos de ubicación denegados.")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            isAuthorized = false
            print("Estado desconocido de autorización.")
        }
        isRequestingAuthorization = false
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.handleAuthorizationStatus(manager.authorizationStatus)
        }
    }

    private func startUpdatingLocation() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self?.locationManager.distanceFilter = 50
            self?.locationManager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !isProcessingRequest, let bestLocation = locations.last else { return }

        latitude = String(format: "%.6f", bestLocation.coordinate.latitude)
        longitude = String(format: "%.6f", bestLocation.coordinate.longitude)

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
