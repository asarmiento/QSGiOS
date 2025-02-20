import SwiftUI

struct TimeRecordsView: View {
    @StateObject private var timeRecordsViewModel = TimeRecordsViewModel()
    @State private var selectedEmployeeId: Int?
    @State private var selectedDate: Date = Date()
    @State private var selectedType: String = "Entrada" // O "Salida"
    
    var body: some View {
        NavigationStack {
            VStack {
                // Filtros
                HStack {
                    VStack{
                        Picker("Empleado", selection: $selectedEmployeeId) {
                            ForEach(timeRecordsViewModel.employees, id: \.id) { employee in
                                Text(employee.name).tag(employee.id as Int?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(minWidth: 200)
                        DatePicker("Fecha", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .frame(minWidth: 200, minHeight: 50)

                        Picker("Tipo", selection: $selectedType) {
                            Text("Entrada").tag("Entrada")
                            Text("Salida").tag("Salida")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(minWidth: 200)
                    }
                    
                  
                }
                .padding()
                
                // Tabla de registros
                if timeRecordsViewModel.isLoading {
                    ProgressView("Cargando...")
                } else if let errorMessage = timeRecordsViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else {
                    List(timeRecordsViewModel.filteredRecords(selectedEmployeeId: selectedEmployeeId, selectedDate: selectedDate, selectedType: selectedType)) { record in
                        VStack(alignment: .leading) {
                            Text("Empleado: \(record.employee.name)")
                                .font(.headline)
                            Text("Fecha: \(record.date)")
                            Text("Hora: \(record.time)")
                            Text("Tipo: \(record.type)")
                                .font(.subheadline)
                                .foregroundColor(.black)
                        }
                        .padding(1)
                    }.scrollDisabled(false)
                }
                
                // Paginación
                HStack {
                    if let prevPageURL = timeRecordsViewModel.prevPageURL {
                        Button("Anterior") {
                            timeRecordsViewModel.loadPage(url: prevPageURL)
                        }
                    }
                    
                    if let nextPageURL = timeRecordsViewModel.nextPageURL {
                        Button("Siguiente") {
                            timeRecordsViewModel.loadPage(url: nextPageURL)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Registros de Horas")
            .onAppear {
                timeRecordsViewModel.fetchTimeRecords()
                timeRecordsViewModel.fetchEmployees()
            }
        }
    }
} 
