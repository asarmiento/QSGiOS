//
//  ListRecordTotals.swift
//  QGS
//
//  Created by Edin Martinez on 11/19/24.
//

import SwiftUI

struct ListRecordTotals: View {
    @StateObject private var networkListTotal = NetworkListTotal() // Crea una instancia del ViewModel
    
    var body: some View {
        NavigationStack {
            HeadSecondary(title: "Total de Horas Semanal")
            VStack {
                if networkListTotal.isLoading {
                    ProgressView("Cargando...") // Muestra un loading mientras se obtienen los datos
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let errorMessage = networkListTotal.errorMessage {
                    Text(errorMessage) // Muestra un error si algo falla
                        .foregroundColor(.red)
                } else {
                    List(networkListTotal.totalHours) { totalHour in
                        VStack(alignment: .leading) {
                            
                            Text("Fecha Inicio: \(totalHour.weekI)")
                            Text("Fecha Fin: \(totalHour.weekF)")
                            Text("Total Horas: \(totalHour.hours)")
                        }
                        .padding()
                    }
                }
            }
            .offset(y: -60)
            .frame(height: 510)
            .onAppear {
                networkListTotal.fetchWorkEntries()
            }
        }
    }
}

#Preview() {
    ListRecordTotals()
}
