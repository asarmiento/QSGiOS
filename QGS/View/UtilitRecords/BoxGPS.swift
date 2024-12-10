//
//  BoxGPS.swift
//  QGS
//
//  Created by Anwar Sarmiento on 11/19/24.
//

import SwiftUI

struct BoxGPS:View
{
    @StateObject var locationManager = LocationViewController.shared // Usa la instancia compartida
      
    var body: some View {
            HStack {
                Group {
                    Label {
                        VStack {
                            Text("LATITUDE")
                                .font(.system(size: 20, weight: .bold))
                                .padding(5)
                            Text(locationManager.latitude.isEmpty ? "0.0" : locationManager.latitude)
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                                .padding(5)
                        }
                    } icon: {}

                    Label {
                        VStack {
                            Text("LONGITUDE")
                                .font(.system(size: 20, weight: .bold))
                                .padding(5)
                            Text(locationManager.longitude.isEmpty ? "0.0" : locationManager.longitude)
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                                .padding(5)
                        }
                    } icon: {}
                }
                .frame(width: 150, height: 80)
                .border(Color.black, width: 1)
            }
        }
}
