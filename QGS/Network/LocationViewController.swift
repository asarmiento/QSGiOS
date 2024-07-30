//
//  LocationViewController.swift
//  QGS
//
//  Created by Edin Martinez on 7/31/24.
//

import Foundation
import CoreLocation
import MapKit

final class LocationViewController: NSObject, ObservableObject{
    private struct Span {
        static let delta = 0.1
    }
    @Published var userLocation: MKCoordinateRegion = .init()
    
    private let locationManager: CLLocationManager = .init()
    
    override init() {
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
    }
}

extension LocationViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return}        
        
        print("Location \(location.coordinate.latitude) Longitude \(location.coordinate.longitude)")
        userLocation = .init(center: location.coordinate, span: .init(latitudeDelta: Span.delta, longitudeDelta: Span.delta))
    }
}
