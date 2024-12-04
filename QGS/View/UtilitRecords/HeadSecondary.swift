//
//  HeadSecondary.swift
//  QGS
//
//  Created by Edin Martinez on 11/19/24.
//

import SwiftUI

struct HeadSecondary: View {
    var title: String = ""
    var body: some View {
        VStack(spacing: 0){
            Color.myPrimary.frame(width: 1000, height: 270).contentMargins(.zero).overlay(content: {
                
                Text(title).foregroundColor(.white).opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
                    .font(.system(size: 36,design: .default) ).bold()
                    .frame(width: 300,height:250,alignment: .center).offset( x:-40, y: 10)
                    .fixedSize(horizontal: false, vertical: true)
            })
            
            ZStack{
                Circle().fill(Color.myPrimary).frame(width:120,height:120).shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/).overlay(
                    Image("QGS").resizable().scaledToFit().padding(.horizontal, 8)
                )
                .clipShape(Circle())
                .overlay( Circle().stroke(Color.white,lineWidth: 2))
                .offset(x:100, y:-60)
            }
            Color.white.edgesIgnoringSafeArea(.bottom)
        }.edgesIgnoringSafeArea(.top)
       
        
             
        
        
         }
}

#Preview {
    HeadSecondary(title: "Bienvenido Anwar Sarmiento")
}
