//
//  ListRecordTotals.swift
//  QGS
//
//  Created by Edin Martinez on 11/19/24.
//

import SwiftUI

struct ListRecordTotals: View {
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var networkListTotal = NetworkListTotal() // Crea una instancia del ViewModel
    private var isloading:Bool = true
    @State private var showPDFView = false
    @State private var showTimeRecordView = false
    private var counterLis: Int = 0
    var body: some View {
        NavigationStack {
           
                
                VStack{
                    HeadSecondary(title: "Total de Horas Semanal", showPDFView: $showPDFView, showTimeRecordView: $showTimeRecordView)
                    VStack {
                        if networkListTotal.isLoading {
                            ProgressView("Cargando...") // Muestra un loading mientras se obtienen los datos
                                .progressViewStyle(CircularProgressViewStyle())
                        } else if let errorMessage = networkListTotal.errorMessage {
                            Text(errorMessage) // Muestra un error si algo falla
                                .foregroundColor(.red)
                        } else {
                            if networkListTotal.totalHours.isEmpty {
                                Text("No hay registros para mostrar.")
                                    .foregroundColor(.gray)
                                    .bold()
                                    .font(.title)
                            } else {
                                ZStack {
                                    Color.white.edgesIgnoringSafeArea(.all) // Fondo blanco principal
                                    List(networkListTotal.totalHours) { totalHour in
                                        VStack(alignment: .leading) {
                                            Text("Fecha Inicio: \(totalHour.weekI)")
                                                .foregroundColor(.black)
                                            Text("Fecha Fin: \(totalHour.weekF)")
                                                .foregroundColor(.black)
                                            Text("Total Horas: \(totalHour.hours)")
                                                .foregroundColor(.black)
                                        }
                                        .padding()
                                        .listRowBackground(Color.white) // Fondo blanco para la celda
                                    }
                                    .scrollContentBackground(.hidden)
                                    .background(Color.white)            // Fondo de la lista
                                }
                            }
                        }
                    }
                    .navigationDestination(isPresented: $showPDFView) {
                        PDFView(url: URL(string: "https://api.friendlypayroll.net/weekly-hours")!)
                    }
                    .navigationDestination(isPresented: $showTimeRecordView) {
                        TimeRecordsView()
                    }
                    .offset(y: -60)
                    .frame(height: 510)
                    .onAppear {
                        print("Llamando a fetchWorkEntries...")
                        networkListTotal.fetchWorkEntries()
                    }
                }
            }
        }
    }

#Preview() {
    ListRecordTotals()
}
