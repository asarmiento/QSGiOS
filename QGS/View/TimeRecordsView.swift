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
        formatter.dateFormat = "dd/MM/yyyy" // Formato consistente con el API
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
        HStack {
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
            
            Spacer()
            
            NavigationLink(destination: AddTimeRecordView(viewModel: viewModel)) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Nuevo registro")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green)
                .cornerRadius(8)
            }
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
        List {
            ForEach(records) { record in
                NavigationLink(destination: EditTimeRecordView(record: record)) {
                    RecordRow(record: record)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical, 2)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// Fila de registro
struct RecordRow: View {
    let record: TimeRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Empleado: \(record.employee.name)")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
            
            Text("Fecha: \(record.date)")
            Text("Hora: \(record.time)")
            
            if let project = record.project {
                Text("Proyecto: \(project.name)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if record.type == "Salida" {
                HStack {
                    Text("Horas: \(formatHours(record.hours))")
                    
                    if let observation = record.observation, !observation.isEmpty {
                        Spacer()
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            
            Text("Tipo: \(record.type)")
                .font(.subheadline)
                .padding(.top, 2)
            
            if let observation = record.observation, !observation.isEmpty {
                Text("Observación: \(observation)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func formatHours(_ hours: Double?) -> String {
        if let hours = hours {
            return String(format: "%.2f", hours)
        } else {
            return "No registradas"
        }
    }
}

// Vista para editar un registro de tiempo
struct EditTimeRecordView: View {
    let record: TimeRecord
    @StateObject private var viewModel = TimeRecordsViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    @State private var hours: String
    @State private var observation: String
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    init(record: TimeRecord) {
        self.record = record
        self._hours = State(initialValue: record.hours != nil ? String(format: "%.2f", record.hours!) : "")
        self._observation = State(initialValue: record.observation ?? "")
    }
    
    var body: some View {
        Form {
            Section(header: Text("Información del registro")) {
                HStack {
                    Text("Empleado:")
                    Spacer()
                    Text(record.employee.name)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Fecha:")
                    Spacer()
                    Text(record.date)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Hora:")
                    Spacer()
                    Text(record.time)
                        .foregroundColor(.secondary)
                }
                
                if let project = record.project {
                    HStack {
                        Text("Proyecto:")
                        Spacer()
                        Text(project.name)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("Tipo:")
                    Spacer()
                    Text(record.type)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Editar información")) {
                if record.type == "Salida" {
                    HStack {
                        Text("Horas:")
                        Spacer()
                        TextField("Horas trabajadas", text: $hours)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                } else {
                    Text("Las horas solo se pueden editar en registros de salida")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading) {
                    Text("Observación:")
                    TextEditor(text: $observation)
                        .frame(minHeight: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            
            Section {
                Button(action: saveChanges) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Guardar cambios")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .disabled(isLoading || (record.type == "Salida" && !isValidHours(hours)))
            }
        }
        .navigationTitle("Editar Registro")
        .navigationBarItems(trailing: Button("Cancelar") {
            presentationMode.wrappedValue.dismiss()
        })
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(isSuccess ? "Éxito" : "Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("Aceptar")) {
                    if isSuccess {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
    }
    
    private func saveChanges() {
        isLoading = true
        
        // Convertir horas a Double
        let hoursValue: Double
        if record.type == "Salida" && !hours.isEmpty {
            hoursValue = Double(hours.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        } else {
            hoursValue = record.hours ?? 0.0
        }
        
        Task {
            let success = await viewModel.updateTimeRecord(
                id: record.id,
                hours: hoursValue,
                observation: observation
            )
            
            DispatchQueue.main.async {
                isLoading = false
                isSuccess = success
                alertMessage = viewModel.updateMessage
                showAlert = true
            }
        }
    }
    
    private func isValidHours(_ hoursString: String) -> Bool {
        if hoursString.isEmpty {
            return false
        }
        
        let cleanedString = hoursString.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleanedString) else {
            return false
        }
        
        return value > 0 && value <= 24
    }
}

// Vista para agregar un nuevo registro de tiempo
struct AddTimeRecordView: View {
    @ObservedObject var viewModel: TimeRecordsViewModel
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var locationController = LocationViewController.shared
    
    @State private var selectedEmployeeId: Int?
    @State private var selectedDate = Date()
    @State private var selectedType = "Salida"
    @State private var hours = ""
    @State private var observation = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @State private var showLocationAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("Información del registro")) {
                // Selector de empleado
                Picker("Empleado", selection: $selectedEmployeeId) {
                    Text("Seleccionar empleado").tag(nil as Int?)
                    ForEach(viewModel.employees, id: \.id) { employee in
                        Text(employee.name).tag(employee.id as Int?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                // Selector de fecha
                DatePicker("Fecha", selection: $selectedDate, displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "es"))
                
                // Selector de tipo
                Picker("Tipo", selection: $selectedType) {
                    Text("Entrada").tag("Entrada")
                    Text("Salida").tag("Salida")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section(header: Text("Detalles")) {
                if selectedType == "Salida" {
                    HStack {
                        Text("Horas:")
                        Spacer()
                        TextField("Horas trabajadas", text: $hours)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                } else {
                    Text("Las horas solo se aplican a registros de salida")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading) {
                    Text("Observación:")
                    TextEditor(text: $observation)
                        .frame(minHeight: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            
            Section(header: Text("Ubicación")) {
                HStack {
                    Image(systemName: locationController.isAuthorized ? "location.fill" : "location.slash.fill")
                        .foregroundColor(locationController.isAuthorized ? .green : .red)
                    
                    Text(locationController.isAuthorized ? "Ubicación disponible" : "Ubicación no disponible")
                    
                    Spacer()
                    
                    if !locationController.isAuthorized {
                        Button("Permitir") {
                            locationController.requestLocationPermission()
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            
            Section {
                Button(action: saveNewRecord) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Guardar registro")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .disabled(isLoading || selectedEmployeeId == nil || (selectedType == "Salida" && !isValidHours(hours)))
            }
        }
        .navigationTitle("Nuevo Registro")
        .onAppear {
            // Verificar permisos de ubicación al cargar la vista
            if !locationController.isAuthorized {
                showLocationAlert = true
            }
        }
        .alert(isPresented: $showLocationAlert) {
            Alert(
                title: Text("Permiso de ubicación"),
                message: Text("Para registrar correctamente su entrada/salida, necesitamos acceder a su ubicación. Por favor, conceda el permiso cuando se le solicite."),
                dismissButton: .default(Text("Entendido")) {
                    locationController.requestLocationPermission()
                }
            )
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(isSuccess ? "Éxito" : "Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("Aceptar")) {
                    if isSuccess {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
    }
    
    private func saveNewRecord() {
        guard let employeeId = selectedEmployeeId else {
            alertMessage = "Por favor, selecciona un empleado"
            showAlert = true
            return
        }
        
        // Verificar si tenemos permiso de ubicación
        if !locationController.isAuthorized {
            alertMessage = "Se requiere acceso a la ubicación para registrar la entrada/salida. Por favor, conceda el permiso."
            showAlert = true
            locationController.requestLocationPermission()
            return
        }
        
        isLoading = true
        
        // Convertir horas a Double si es un registro de salida
        let hoursValue: Double?
        if selectedType == "Salida" && !hours.isEmpty {
            hoursValue = Double(hours.replacingOccurrences(of: ",", with: "."))
        } else {
            hoursValue = nil
        }
        
        // Formatear la fecha
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)
        
        // Formatear la hora actual
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        let timeString = timeFormatter.string(from: Date())
        
        Task {
            let success = await viewModel.createTimeRecord(
                employeeId: employeeId,
                date: dateString,
                time: timeString,
                type: selectedType,
                hours: hoursValue,
                observation: observation
            )
            
            DispatchQueue.main.async {
                isLoading = false
                isSuccess = success
                alertMessage = viewModel.updateMessage
                showAlert = true
                
                if success {
                    // Recargar los registros después de crear uno nuevo
                    Task {
                        await viewModel.fetchTimeRecords()
                    }
                }
            }
        }
    }
    
    private func isValidHours(_ hoursString: String) -> Bool {
        if hoursString.isEmpty {
            return false
        }
        
        let cleanedString = hoursString.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleanedString) else {
            return false
        }
        
        return value > 0 && value <= 24
    }
}
