//
//  HeadSecondary.swift
//  QGS
//
//  Created by Edin Martinez on 11/19/24.
//
import Foundation
import SwiftUI



struct HeadSecondary: View {
    var title: String = ""
    
    var body: some View {
        VStack(spacing: 0) {

            Color("myPrimaries").frame(width: 1000, height: 250).contentMargins(.zero).overlay(content: {
              
        
                Text(NSLocalizedString(title,comment: "el titulo de bienvenidad")).foregroundColor(.white).opacity(0.8)
                    .font(.system(size: 36, design: .default)).bold()
                    .frame(width: 300, height: 250, alignment: .center).offset(x: -40, y: 10)
                    .fixedSize(horizontal: false, vertical: true)
            })
            
            ZStack {
                Circle().fill(Color("myPrimaries")).frame(width: 120, height: 120).shadow(radius: 10).overlay(
                    Image("icon-white").resizable().scaledToFit().padding(.horizontal, 8)
                )
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .offset(x: 100, y: -60)
            }
            Color.white.edgesIgnoringSafeArea(.bottom)

            
        }
        .edgesIgnoringSafeArea(.top)
    }
    
 
}

#Preview {
    HeadSecondary(title: "Título de Ejemplo")
} 
