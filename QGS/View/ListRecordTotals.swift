//
//  ListRecordTotals.swift
//  QGS
//
//  Created by Edin Martinez on 11/19/24.
//

import SwiftUI

struct ListRecordTotals: View {
    var body: some View {
        NavigationView {
            ZStack {
                HeadSecondary(title: "Totales por Semana")
                
               VStack{
                   Spacer(minLength:250)
                  
                    List {
                        Group{
                            Text("A List Item")
                            Text("A Second List Item")
                            Text("A Third List Item")
                        }
                    }.padding(-1).background(Color.myPrimary)
                }
                
            }
        }
    }
}

#Preview() {
    ListRecordTotals()
}
