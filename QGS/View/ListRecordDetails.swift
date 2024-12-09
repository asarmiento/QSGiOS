//
//  ListRecordDetails.swift
//  QGS
//
//  Created by Edin Martinez on 11/19/24.
//
import Foundation
import SwiftUI
import SwiftData



struct ListRecordDetails: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var networkListDetails = NetworkListDetails() // Crea una instancia del ViewModel
    
    var body: some View {
        NavigationStack {
            HeadSecondary(title: "Registro de entradas y salidas")
            VStack {
                if networkListDetails.isLoading {
                    ProgressView("Cargando...") // Muestra un loading mientras se obtienen los datos
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let errorMessage = networkListDetails.errorMessage {
                    Text(errorMessage) // Muestra un error si algo falla
                        .foregroundColor(.red)
                } else {
                    if !networkListDetails.workEntries.isEmpty {
                        
                        List(networkListDetails.workEntries) { workEntry in
                            
                            VStack(alignment: .leading) {
                                
                                Text("Proyecto: \(workEntry.project.name)")
                                    .font(.subheadline)
                                HStack {
                                    Text("Fecha: \(workEntry.date)")
                                    Text("Hora: \(workEntry.time)")
                                }
                                Text("Tipo: \(workEntry.type)")
                                
                            }
                            .padding()
                        }
                    }else{
                        Text("No hay entradas y salidas registradas")
                            .foregroundStyle(.gray).bold().font(.title)
                    }
                }
            }.offset(y: -60).frame( height: 510 )
            
                .onAppear {
                    networkListDetails.context = modelContext
                    networkListDetails.fetchWorkEntries()
                }
        }
    }
}


#Preview{
    ListRecordDetails()
}




