//
//  LocationViewController.swift
//  QGS
//
//  Created by Anwar Sarmiento on 7/31/24.
//
import Foundation
import CoreLocation
import SwiftUI
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
        // Asigna delegado y chequea autorizacion
        locationManager.delegate = self
        checkAuthorization()
    }

    // MARK: - Chequeo de Autorización

    func checkAuthorization() {
        let currentStatus: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            currentStatus = locationManager.authorizationStatus
        } else {
            currentStatus = CLLocationManager.authorizationStatus()
        }
        isAuthorized = (currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways)
    }

    func requestLocationPermission() {
        guard !isRequestingAuthorization else { return }
        isRequestingAuthorization = true

        // Mover la llamada a un hilo de mayor prioridad (o background)
        DispatchQueue.global(qos: .userInitiated).async {
            if CLLocationManager.locationServicesEnabled() {
                let status: CLAuthorizationStatus
                if #available(iOS 14.0, *) {
                    status = self.locationManager.authorizationStatus
                } else {
                    status = CLLocationManager.authorizationStatus()
                }

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
                    self.isRequestingAuthorization = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isAuthorized = false
                    print("Servicios de localización desactivados")
                    self.isRequestingAuthorization = false
                }
            }
        }
    }


    // MARK: - Manejo de autorización en tiempo de ejecución

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

    // MARK: - Inicio / Detención de la ubicación

    private func startUpdatingLocation() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        print("Iniciando actualización de ubicación")
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        print("Deteniendo actualización de ubicación")
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // iOS 14+
        let status = manager.authorizationStatus
        handleAuthorizationStatus(status)
    }

    // Para iOS < 14
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleAuthorizationStatus(status)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !isProcessingRequest, let bestLocation = locations.last else { return }
        isProcessingRequest = true

        latitude = String(format: "%.6f", bestLocation.coordinate.latitude)
        longitude = String(format: "%.6f", bestLocation.coordinate.longitude)

        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(bestLocation) { [weak self] placemarks, error in
            defer { self?.isProcessingRequest = false }
            guard let self = self else { return }

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
                print("Dirección: \(self.address)")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error al obtener la ubicación: \(error.localizedDescription)")
    }
}
