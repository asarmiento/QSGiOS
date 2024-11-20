//
//  TotalRecords.swift
//  QGS
//
//  Created by Edin Martinez on 11/18/24.
//

import SwiftUI

struct TotalRecords: View {
    var body: some View {
        NavigationView {
            ZStack {
                Rectangle().size(CGSize(width: 400, height: 200.0)).fill(Color.myPrimary)
                                Circle().scale(0.2).fill(Color.myPrimary).position(CGPoint(x: 340.0, y: 200.0))
               
                
                VStack{
                HStack{
                    Button("Hola"){ }.padding(10).frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
                    Button("Hola"){ }.padding(10).frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
                    Button("Hola"){ }.padding(10).frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
                    
           
                }
                }
                
            }
            
        }
    }
}

#Preview {
    TotalRecords()
}
