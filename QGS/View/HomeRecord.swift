//
//  HomeRecord.swift
//  QGS
//
//  Created by Edin Martinez on 7/31/24.
//

import UIKit
import SwiftUI

struct HomeRecord: View {
    @StateObject var locationViewModel = LocationViewController()
    var body: some View {
        NavigationView{
            ZStack{
                Color.myPrimary.ignoresSafeArea()
                Circle().scale(1.8)
                    .foregroundColor(.white.opacity(0.15))
                Circle().scale(1.6)
                    .foregroundColor(.white.opacity(0.15))
                
                Circle().scale(1.4).foregroundColor(.white)
                VStack{
                    Text("Registro de Entrada y Salida del trabajo").font(.largeTitle.bold()).hSpacing(.center)
                   
                    VStack{
                        Group{
                            
                            Text("Longitud: \(locationViewModel.userLocation.center.longitude)").italic()
                                .hSpacing( .center)
                            
                            Text("Latitud: \(locationViewModel.userLocation.center.latitude)").italic()
                                .hSpacing( .center)
                            
                        }.frame(width: 350, height: 50, alignment: .leading).font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                            .border(Color.myPrimary).padding()
                        
                        Button("Entrada"){
                            
                        }.padding()
                            .frame(width: 300, height: 50, alignment: .center)
                        
                        Button("Salida"){
                            
                        }.background(Color.myPrimary).hidden()
                            .frame(width: 300, height: 50, alignment: .bottom).padding()
                    }
                }.frame(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            }}
        
          
    }
}
func HiddieButton(){
    
}
#Preview {
    HomeRecord()
}
