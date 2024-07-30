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
                Text("Registro").font(.largeTitle.bold())
                Color.myPrimary.ignoresSafeArea()
                Circle().scale(1.8)
                    .foregroundColor(.white.opacity(0.15))
                Circle().scale(1.6)
                    .foregroundColor(.white.opacity(0.15))
                
                Circle().scale(1.4).foregroundColor(.white)
                VStack{
                    Group{
                    
                        Text("Longitud ") //\(locationViewModel.userLocation.longitude)
                        
                        Text("Latitud ")// \(locationViewModel.userLocation.latitude)
                        
                    }.frame(width: 350, height: 50, alignment: .leading).font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        .border(/*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/).padding().padding(.leading, 2)
                    
                    Button("Entrada"){
                        
                    }.padding()
                        .frame(width: 300, height: 50, alignment: .center)
                    
                    Button("Salida"){
                        
                    }.padding().hidden()
                        .frame(width: 300, height: 50, alignment: .bottom)
                }
            }.frame(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
        }
        
          
    }
}
func HiddieButton(){
    
}
#Preview {
    HomeRecord()
}
