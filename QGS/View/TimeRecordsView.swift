import SwiftUI
import FirebaseAnalytics

struct TimeRecordsView: View {
    @StateObject private var timeRecordsViewModel = TimeRecordsViewModel()
    
    @State private var selectedEmployeeId: Int?
    @State private var selectedDates: Set<DateComponents> = []  // Múltiples fechas
    @State private var selectedType: String = "Entrada"         // O "Salida"
    let oneMonthAgo: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    
    private func logFilterEvent(employeeId: Int?, dates: Set<DateComponents>, type: String) {
        Analytics.logEvent("filter_records", parameters: [
            "employee_id": employeeId as Any,
            "date_count": dates.count,
            "type": type
        ])
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                VStack(spacing: 0) {
                    
                    // ---------- Sección de Filtros (50%) ----------
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Texto "Registros de Horas"
                            Text("Registros de Horas")
                                .font(.title)
                                .padding(.top, 2)
                            
                            // 1) Picker Empleado
                            VStack(alignment: .leading) {
                                Text("Empleado")
                                    .font(.headline)
                                
                                Picker("Empleado", selection: $selectedEmployeeId) {
                                    Text("Todos").tag(nil as Int?)
                                    ForEach(timeRecordsViewModel.employees, id: \.id) { employee in
                                        Text(employee.name).tag(employee.id as Int?)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(5)
                                .onChange(of: selectedEmployeeId) { _ in
                                    logFilterEvent(
                                        employeeId: selectedEmployeeId,
                                        dates: selectedDates,
                                        type: selectedType
                                    )
                                }
                            }
                            
                            Divider()
                            
                            // 2) MultiDatePicker (1 mes atrás...hoy)
                            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                            
                            VStack(alignment: .leading) {
                                Text("Selecciona las fechas")
                                    .font(.headline)
                                
                                MultiDatePicker("Fechas", selection: $selectedDates, in: oneMonthAgo..<tomorrow)
                                    .datePickerStyle(GraphicalDatePickerStyle())
                                    .frame(maxHeight: 300) // Altura controlada
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(4)
                                    .environment(\.locale, Locale(identifier: "es"))
                            }
                            
                            Divider()
                            
                            // 3) Picker Tipo (Segmented)
                            VStack(alignment: .leading) {
                                Text("Tipo de Registro")
                                    .font(.headline)
                                
                                Picker("Tipo", selection: $selectedType) {
                                    Text("Entrada").tag("Entrada")
                                    Text("Salida").tag("Salida")
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .onChange(of: selectedType) { _ in
                                    logFilterEvent(
                                        employeeId: selectedEmployeeId,
                                        dates: selectedDates,
                                        type: selectedType
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                    .frame(height: proxy.size.height * 0.5) // Ocupa la mitad superior de la pantalla
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 5)

                    // ---------- Sección de Lista (50%) ----------
                    VStack {
                        if timeRecordsViewModel.isLoading {
                            ProgressView("Cargando...")
                        } else if let errorMessage = timeRecordsViewModel.errorMessage {
                            Text(errorMessage).foregroundColor(.red)
                        } else {
                            List(
                                timeRecordsViewModel.filteredRecordsMultipleDates(
                                    selectedEmployeeId: selectedEmployeeId,
                                    selectedDates: selectedDates,
                                    selectedType: selectedType
                                )
                            ) { record in
                                VStack(alignment: .leading) {
                                    Text("Empleado: \(record.employee.name)")
                                        .font(.headline)
                                    Text("Fecha: \(record.date)")
                                    Text("Hora de Registro: \(record.time)")
                                    if(record.type == "Salida"){
                                        Text("Horas: \(record.hours)")
                                    }
                                    Text("Tipo: \(record.type)")
                                        .font(.subheadline)
                                   
                                }
                                .padding(4)
                            }
                        }
                    }
                    .frame(height: proxy.size.height * 0.5) // La lista ocupa la mitad inferior
                }
            }
            .onAppear {
                // Registrar vista en Analytics
                if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                    appDelegate.logScreenView(screenName: "TimeRecords",
                                            screenClass: "TimeRecordsView")
                }
                
                timeRecordsViewModel.fetchTimeRecords()
                timeRecordsViewModel.fetchEmployees()
            }
        }
    }

} 
