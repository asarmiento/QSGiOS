//
//  BoxGPS.swift
//  QGS
//
//  Created by Anwar Sarmiento on 11/19/24.
//

import SwiftUI

struct BoxGPS:View
{
    @StateObject var locationManager = LocationManager()
    
    var body: some View {
        HStack{
            Group {
                
                Label{
                    VStack{ Text(
                        "LATITUDE"
                    ).font(
                        .system(
                            size: 20,
                            weight: .bold
                        )
                    ).contentMargins(5).padding(5)
                        Text(
                            String(locationManager.latitude)
                        ).font(
                            .system(
                                size: 16
                            )
                        ).contentMargins(5).padding(5)}
                } icon:{
                }
                Label{
                    VStack{
                        Text(
                            String(
                                "LONGITUDE"
                            )
                        ).font(
                            .system(
                                size: 20,
                                weight: .bold
                            )
                        ).contentMargins(5).padding(5)
                        Text(
                            String(
                                locationManager.longitude
                            )
                        ).font(
                            .system(
                                size: 16
                            )
                        ).contentMargins(5).padding(5)
                        
                    }
                    
                } icon:{
                }
            }.shadow(
                color:Color.myPrimary,
                radius:50,
                x:10,
                y:24
            )
            .frame(
                width: 150,
                height: 80,
                alignment: .center
            )
            .font(
                .title
            )
            .padding()
            .padding(
                .leading,
                2
            ).border(
                /*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/,
                                      width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/
            )
        }}
}
