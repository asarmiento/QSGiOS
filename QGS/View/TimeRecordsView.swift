
import Foundation
import SwiftUI
import FirebaseAnalytics

struct TimeRecordsView: View {
    @StateObject private var viewModel = TimeRecordsViewModel()
    
    @State private var selectedEmployeeId: Int?
    @State private var selectedDates: Set<DateComponents> = []
    @State private var selectedType: String = "Entrada"
    
    let oneMonthAgo: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                VStack(spacing: 0) {
                    // Sección de Filtros
                    FilterSection(
                        proxy: proxy,
                        viewModel: viewModel,
                        selectedEmployeeId: $selectedEmployeeId,
                        selectedDates: $selectedDates,
                        selectedType: $selectedType,
                        oneMonthAgo: oneMonthAgo
                    )
                    
                    // Sección de Lista
                    RecordListSection(
                        proxy: proxy,
                        viewModel: viewModel
                    )
                }
            }
            .onAppear {
                if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                    appDelegate.logScreenView(
                        screenName: "TimeRecords",
                        screenClass: "TimeRecordsView"
                    )
                }
                
                viewModel.fetchTimeRecords()
                viewModel.fetchEmployees()
            }
        }
    }
}

// MARK: - Componentes de la vista

// Sección de Filtros
struct FilterSection: View {
    let proxy: GeometryProxy
    @ObservedObject var viewModel: TimeRecordsViewModel
    @Binding var selectedEmployeeId: Int?
    @Binding var selectedDates: Set<DateComponents>
    @Binding var selectedType: String
    let oneMonthAgo: Date
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Registros de Horas")
                    .font(.title)
                    .padding(.top, 2)
                
                // Picker Empleado
                EmployeePicker(
                    viewModel: viewModel,
                    selectedEmployeeId: $selectedEmployeeId,
                    selectedDates: selectedDates,
                    selectedType: selectedType
                )
                
                Divider()
                
                // MultiDatePicker
                DateSelectionView(
                    viewModel: viewModel,
                    selectedEmployeeId: selectedEmployeeId,
                    selectedDates: $selectedDates,
                    selectedType: selectedType,
                    oneMonthAgo: oneMonthAgo
                )
                
                Divider()
                
                // Picker Tipo
                TypePicker(
                    viewModel: viewModel,
                    selectedEmployeeId: selectedEmployeeId,
                    selectedDates: selectedDates,
                    selectedType: $selectedType
                )
                
                // Botón para limpiar filtros
                ClearFiltersButton(
                    viewModel: viewModel,
                    selectedEmployeeId: $selectedEmployeeId,
                    selectedDates: $selectedDates,
                    selectedType: $selectedType
                )
            }
            .padding()
        }
        .frame(height: proxy.size.height * 0.5)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

// Picker de Empleado
struct EmployeePicker: View {
    @ObservedObject var viewModel: TimeRecordsViewModel
    @Binding var selectedEmployeeId: Int?
    let selectedDates: Set<DateComponents>
    let selectedType: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Empleado")
                .font(.headline)
            
            Picker("Empleado", selection: $selectedEmployeeId) {
                Text("Todos").tag(nil as Int?)
                ForEach(viewModel.employees, id: \.id) { employee in
                    Text(employee.name).tag(employee.id as Int?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(5)
            .onChange(of: selectedEmployeeId) { oldValue, newValue in
                viewModel.applyFilters(
                    employeeId: newValue,
                    dates: selectedDates,
                    type: selectedType
                )
                
                logFilterEvent(
                    employeeId: newValue,
                    dates: selectedDates,
                    type: selectedType
                )
            }
        }
    }
    
    private func logFilterEvent(employeeId: Int?, dates: Set<DateComponents>, type: String) {
        Analytics.logEvent("filter_records", parameters: [
            "employee_id": employeeId as Any,
            "date_count": dates.count,
            "type": type
        ])
    }
}

// Selector de Fechas
struct DateSelectionView: View {
    @ObservedObject var viewModel: TimeRecordsViewModel
    let selectedEmployeeId: Int?
    @Binding var selectedDates: Set<DateComponents>
    let selectedType: String
    let oneMonthAgo: Date
    
    var body: some View {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        VStack(alignment: .leading) {
            Text("Selecciona las fechas")
                .font(.headline)
            
            MultiDatePicker("Fechas", selection: $selectedDates, in: oneMonthAgo..<tomorrow)
                .datePickerStyle(GraphicalDatePickerStyle())
                .frame(maxHeight: 300)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
                .environment(\.locale, Locale(identifier: "es"))
                .onChange(of: selectedDates) { oldValue, newValue in
                    viewModel.applyFilters(
                        employeeId: selectedEmployeeId,
                        dates: newValue,
                        type: selectedType
                    )
                    
                    logFilterEvent(
                        employeeId: selectedEmployeeId,
                        dates: newValue,
                        type: selectedType
                    )
                }
            
            // Mostrar fechas seleccionadas
            if !selectedDates.isEmpty {
                SelectedDatesView(selectedDates: selectedDates)
            }
        }
    }
    
    private func logFilterEvent(employeeId: Int?, dates: Set<DateComponents>, type: String) {
        Analytics.logEvent("filter_records", parameters: [
            "employee_id": employeeId as Any,
            "date_count": dates.count,
            "type": type
        ])
    }
}

// Vista de fechas seleccionadas
struct SelectedDatesView: View {
    let selectedDates: Set<DateComponents>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Fechas seleccionadas:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(Array(selectedDates), id: \.self) { dateComponents in
                        if let date = Calendar.current.date(from: dateComponents) {
                            Text(formatDate(date))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .frame(height: 30)
        }
        .padding(.top, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "es")
        return formatter.string(from: date)
    }
}

// Picker de Tipo
struct TypePicker: View {
    @ObservedObject var viewModel: TimeRecordsViewModel
    let selectedEmployeeId: Int?
    let selectedDates: Set<DateComponents>
    @Binding var selectedType: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Tipo de Registro")
                .font(.headline)
            
            Picker("Tipo", selection: $selectedType) {
                Text("Entrada").tag("Entrada")
                Text("Salida").tag("Salida")
                Text("Todos").tag("Todos")
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedType) { oldValue, newValue in
                viewModel.applyFilters(
                    employeeId: selectedEmployeeId,
                    dates: selectedDates,
                    type: newValue
                )
                
                logFilterEvent(
                    employeeId: selectedEmployeeId,
                    dates: selectedDates,
                    type: newValue
                )
            }
        }
    }
    
    private func logFilterEvent(employeeId: Int?, dates: Set<DateComponents>, type: String) {
        Analytics.logEvent("filter_records", parameters: [
            "employee_id": employeeId as Any,
            "date_count": dates.count,
            "type": type
        ])
    }
}

// Botón para limpiar filtros
struct ClearFiltersButton: View {
    @ObservedObject var viewModel: TimeRecordsViewModel
    @Binding var selectedEmployeeId: Int?
    @Binding var selectedDates: Set<DateComponents>
    @Binding var selectedType: String
    
    var body: some View {
        Button(action: {
            selectedEmployeeId = nil
            selectedDates = []
            selectedType = "Todos"
            viewModel.clearFilters()
        }) {
            Text("Limpiar filtros")
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red)
                .cornerRadius(8)
        }
        .padding(.top, 8)
    }
}

// Sección de Lista de Registros
struct RecordListSection: View {
    let proxy: GeometryProxy
    @ObservedObject var viewModel: TimeRecordsViewModel
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Cargando...")
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            } else if viewModel.filteredRecords.isEmpty {
                EmptyRecordsView()
            } else {
                RecordsList(records: viewModel.filteredRecords)
            }
        }
        .frame(height: proxy.size.height * 0.5)
    }
}

// Vista para cuando no hay registros
struct EmptyRecordsView: View {
    var body: some View {
        VStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
                .padding()
            
            Text("No se encontraron registros con los filtros seleccionados")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

// Lista de registros
struct RecordsList: View {
    let records: [TimeRecord]
    
    var body: some View {
        List(records) { record in
            RecordRow(record: record)
        }
    }
}

// Fila de registro
struct RecordRow: View {
    let record: TimeRecord
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Empleado: \(record.employee.name)")
                .font(.headline)
            Text("Fecha: \(record.date)")
            Text("Hora de Registro: \(record.time)")
            if record.type == "Salida", let hours = record.hours {
                Text("Horas: \(String(format: "%.2f", hours))")
            }
            Text("Tipo: \(record.type)")
                .font(.subheadline)
        }
        .padding(4)
    }
}
