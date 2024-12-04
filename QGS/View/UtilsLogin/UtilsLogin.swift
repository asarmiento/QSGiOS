//
//  HeadSecondary.swift
//  QGS
//
//  Created by Edin Martinez on 11/19/24.
//

import SwiftUI

struct HeadLogin: View {
    var title: String = ""
    var body: some View {
        VStack(spacing: 0){
            Color.myPrimary.frame(width: 1000, height: 270).contentMargins(.zero)
            
            Image("QGS-Branding-01")
                .resizable()
                .scaledToFit()
                .frame(width: 220)
            
            Color.white.edgesIgnoringSafeArea(.bottom)
        }.edgesIgnoringSafeArea(.top)
       
         }
}

#Preview {
    HeadSecondary(title: "Hello, World!")
}
