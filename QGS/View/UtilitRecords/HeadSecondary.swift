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
        
        Rectangle().size(CGSize(width:500.0, height: 200.0)).fill(Color.myPrimary).contentMargins(.bottom,20)
            Circle().scale(0.2).fill(Color.myPrimary).position(CGPoint(x: 340.0, y: 200.0)).shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
            Text(title).foregroundColor(.white).opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/).font(.system(size: 36,design: .default) ).position(x:150,y:160)
        
       
    }
}
