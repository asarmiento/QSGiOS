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
    
    @State private var showPDFView = false
    @State var showTimeRecordView = false 
    
    var body: some View {
        NavigationStack {
      
                VStack {
                    
                    HeadSecondary(title: "Detalle de Horas diarios", showPDFView: $showPDFView, showTimeRecordView: $showTimeRecordView)
                    VStack{
                        if networkListDetails.isLoading {
                            ProgressView("Cargando...")
                                .progressViewStyle(CircularProgressViewStyle())
                        } else if let errorMessage = networkListDetails.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                        } else {
                            if !networkListDetails.workEntries.isEmpty {
                                ZStack {
                                    Color.white.edgesIgnoringSafeArea(.all)  // Fondo blanco general
                                    List(networkListDetails.workEntries) { workEntry in
                                        VStack(alignment: .leading) {
                                            Text("Proyecto: \(workEntry.project.name)")
                                                .font(.headline)
                                                .foregroundColor(.black)
                                            HStack {
                                                Text("Fecha: \(workEntry.date)")
                                                    .foregroundColor(.black)
                                                Text("Horas: \(workEntry.hours != nil ? String(format: "%.2f", workEntry.hours!) : "N/A")")
                                                    .foregroundColor(.black)
                                            }
                                            Text("Hora de Registro: \(workEntry.time)")
                                                .foregroundColor(.black)
                                            Text("Tipo: \(workEntry.type)")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        .padding(1)
                                        .listRowBackground(Color.white)       // Fondo blanco para la fila
                                    }
                                    .scrollContentBackground(.hidden)
                                    .background(Color.white)                 // Fondo de la lista
                                }
                            } else {
                                Text("No hay entradas y salidas registradas")
                                    .foregroundColor(.gray)
                                    .font(.title)
                            }
                        }
                    }
                    .frame(height: 600)
                    .offset(y: -50)
                    .navigationDestination(isPresented: $showPDFView) {
                        PDFView(url: URL(string: "https://api.friendlypayroll.net/weekly-hours")!)
                    }
                    .navigationDestination(isPresented: $showTimeRecordView) {
                        TimeRecordsView()
                    }
                    .onAppear {
                        networkListDetails.context = modelContext
                        networkListDetails.fetchWorkEntries()
                    }}
            }
        }
}


#Preview{
    ListRecordDetails()
}




