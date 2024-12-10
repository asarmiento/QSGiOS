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
       @StateObject private var networkListDetails = NetworkListDetails()
       
       var body: some View {
           NavigationStack {
               
               HeadSecondary(title: "Detalle de Horas diarios")
               VStack {
                   if networkListDetails.isLoading {
                       ProgressView("Cargando...")
                           .progressViewStyle(CircularProgressViewStyle())
                   } else if let errorMessage = networkListDetails.errorMessage {
                       Text(errorMessage)
                           .foregroundColor(.red)
                   } else {
                       if !networkListDetails.workEntries.isEmpty {
                           List(networkListDetails.workEntries) { workEntry in
                               VStack(alignment: .leading) {
                                   Text("Proyecto: \(workEntry.project.name)")
                                       .font(.headline)
                                   HStack {
                                       Text("Fecha: \(workEntry.date)")
                                       Text("Horas: \(workEntry.hours != nil ? String(format: "%.2f", workEntry.hours!) : "N/A")")

                                   }
                                   Text("Tipo: \(workEntry.type)")
                                       .font(.subheadline)
                                       .foregroundColor(.gray)
                               }
                               .padding(1)
                           }
                       } else {
                           Text("No hay entradas y salidas registradas")
                               .foregroundColor(.gray)
                               .font(.title)
                       }
                   }
               }.frame(height:600).offset(y: -50)
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




