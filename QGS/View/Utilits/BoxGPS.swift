//
//  BoxGPS.swift
//  QGS
//
//  Created by Anwar Sarmiento on 11/19/24.
//

import SwiftUI
import MapKit

struct BoxGPS: View {
    @StateObject var locationManager = LocationViewController.shared

    var body: some View {
        VStack {
            // Mapa que muestra la ubicación actual
            Map {
                // Añadir una anotación personalizada en la ubicación actual
                Annotation("Current Location", coordinate: CLLocationCoordinate2D(
                    latitude: Double(locationManager.latitude) ?? 0.0,
                    longitude: Double(locationManager.longitude) ?? 0.0
                )) {
                    Image(systemName: "mappin.circle.fill")
                        .resizable()
                        .foregroundColor(.blue)
                        .frame(width: 30, height: 30)
                }
            }
            .mapStyle(.standard)
            .frame(height: 200)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .padding()
    }
}
