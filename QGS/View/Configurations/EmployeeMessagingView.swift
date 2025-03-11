import SwiftUI
import FirebaseCore
import FirebaseMessaging
import FirebaseFirestore

struct EmployeeMessagingView: View {
    @StateObject private var viewModel = EmployeeMessagingViewModel()
    @State private var messageText = ""
    @State private var showingConfirmation = false
    @State private var confirmationMessage = ""
    @State private var isSuccess = false
    @State private var searchText = ""
    @State private var hasAccess: Bool = false
    
    // Función estática para verificar si el usuario tiene acceso
    static func userHasAccess() -> Bool {
        // Verificar si el tipo de usuario no es "employee"
        if let userType = UserManager.shared.userType {
            return userType != "employee"
        }
        return false
    }
    var filteredEmployees: [EmployeeCodable] {
        if searchText.isEmpty {
            return viewModel.employees
        } else {
            return viewModel.employees.filter { employee in
                employee.name.lowercased().contains(searchText.lowercased()) ||
                employee.email.lowercased().contains(searchText.lowercased()) ||
                (employee.user?.code.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if hasAccess {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                            .padding()
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        // Área de búsqueda
                        SearchBar(text: $searchText)
                        
                        // Selector para todos los empleados
                        HStack {
                            Toggle("Seleccionar todos", isOn: $viewModel.selectAll)
                                .onChange(of: viewModel.selectAll) { _, newValue in
                                    viewModel.toggleSelectAll(newValue)
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                            
                            Spacer()
                            
                            Text("\(viewModel.selectedEmployees.count) seleccionados")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        
                        // Lista de empleados
                        List {
                            ForEach(filteredEmployees) { employee in
                                EmployeeSelectionRow(
                                    employee: employee,
                                    isSelected: viewModel.isSelected(employee),
                                    onToggle: { viewModel.toggleSelection(for: employee) }
                                )
                            }
                        }
                        .listStyle(PlainListStyle())
                        
                        // Área de mensaje
                        VStack(alignment: .leading) {
                            Text("Mensaje")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            TextEditor(text: $messageText)
                                .frame(minHeight: 100)
                                .padding(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .padding(.horizontal)
                            
                            // Botón de enviar
                            Button(action: sendMessage) {
                                HStack {
                                    Spacer()
                                    if viewModel.isSending {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .foregroundColor(.white)
                                    } else {
                                        Text("Enviar Mensaje")
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(viewModel.canSendMessage ? Color.blue : Color.gray)
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                            .disabled(!viewModel.canSendMessage)
                        }
                        .padding(.bottom)
                    }
                } else {
                    ZStack {
                        // Marca de agua
                        Image("QGS-Branding-01")
                            .resizable()
                            .scaledToFit()
                            .opacity(0.1)
                        
                        // Mensaje de acceso denegado
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.shield")
                                .font(.system(size: 60))
                                .foregroundColor(.red)
                            
                            Text("Acceso Denegado")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("No tienes permisos para acceder a esta sección.")
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Mensajes a Empleados")
            .onAppear {
                // Verificar si el usuario tiene acceso
                checkUserAccess()
                hasAccess = EmployeeMessagingView.userHasAccess()
                if hasAccess && viewModel.employees.isEmpty {
                    Task {
                        await viewModel.fetchEmployees()
                    }
                }
            }
            .alert(isPresented: $showingConfirmation) {
                Alert(
                    title: Text(isSuccess ? "Éxito" : "Error"),
                    message: Text(confirmationMessage),
                    dismissButton: .default(Text("Aceptar"))
                )
            }
        }
    }
    
    private func checkUserAccess() {
        // Verificar el tipo de usuario desde UserManager
        if let userType = UserManager.shared.userType {
            // Si el usuario es administrador o supervisor, tiene acceso
            hasAccess = userType.lowercased() != "empleado"
        } else {
            hasAccess = false
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty && !viewModel.selectedEmployees.isEmpty else {
            confirmationMessage = "Por favor, escribe un mensaje y selecciona al menos un empleado."
            isSuccess = false
            showingConfirmation = true
            return
        }
        
        Task {
            let result = await viewModel.sendMessage(messageText)
            
            DispatchQueue.main.async {
                switch result {
                case .success:
                    confirmationMessage = "Mensaje enviado correctamente a \(viewModel.selectedEmployees.count) empleado(s)."
                    isSuccess = true
                    messageText = ""
                case .failure(let error):
                    confirmationMessage = "Error al enviar el mensaje: \(error.localizedDescription)"
                    isSuccess = false
                }
                showingConfirmation = true
            }
        }
    }
}

struct EmployeeSelectionRow: View {
    let employee: EmployeeCodable
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(employee.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let code = employee.user?.code {
                        Text("Código: \(code)")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }
                }
                
                Text(employee.phone)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                if let workTypeName = employee.typeWork?.workType?.name {
                    Text(workTypeName)
                        .font(.caption)
                        .padding(4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        .padding(.vertical, 4)
    }
}

// Se eliminó la estructura SearchBar que estaba causando el error de redeclaración
// Asegúrate de importar el archivo que contiene la definición de SearchBar si es necesario

@MainActor
class EmployeeMessagingViewModel: ObservableObject {
    @Published var employees: [EmployeeCodable] = []
    @Published var selectedEmployees: Set<Int> = []
    @Published var isLoading = false
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var selectAll = false
    
    // Desactivamos el modo de simulación para usar la implementación real
    private let simulationMode = false
    
    var canSendMessage: Bool {
        !selectedEmployees.isEmpty && !isSending
    }
    
    func fetchEmployees() async {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            guard let token = UserManager.shared.authToken else {
                self.errorMessage = "No hay token de autenticación"
                self.isLoading = false
                return
            }
            
            let url = URL(string: "https://api.friendlypayroll.net/api/colaboradores/list-employees")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                let employees = try decoder.decode([EmployeeCodable].self, from: data)
                
                self.employees = employees
                self.isLoading = false
            } else {
                throw URLError(.badServerResponse)
            }
        } catch {
            self.errorMessage = "Error: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    func toggleSelection(for employee: EmployeeCodable) {
        if selectedEmployees.contains(employee.id) {
            selectedEmployees.remove(employee.id)
            if selectAll {
                selectAll = false
            }
        } else {
            selectedEmployees.insert(employee.id)
            if selectedEmployees.count == employees.count {
                selectAll = true
            }
        }
    }
    
    func toggleSelectAll(_ select: Bool) {
        if select {
            selectedEmployees = Set(employees.map { $0.id })
        } else {
            selectedEmployees.removeAll()
        }
    }
    
    func isSelected(_ employee: EmployeeCodable) -> Bool {
        selectedEmployees.contains(employee.id)
    }
    
    func sendMessage(_ message: String) async -> Result<Void, Error> {
        self.isSending = true
        
        // Si estamos en modo simulación, usamos el método de simulación
        if simulationMode {
            return await simulateSendMessage(message)
        }
        
        // Implementación real para enviar mensajes
        do {
            // Obtener los empleados seleccionados
            let selectedEmployeesList = employees.filter { selectedEmployees.contains($0.id) }
            
            // Guardar el mensaje en Firestore para que la función de Cloud Functions lo procese
            return try await saveMessageToFirestore(message: message, recipients: selectedEmployeesList)
        } catch {
            print("Error al enviar mensaje: \(error.localizedDescription)")
            self.isSending = false
            return .failure(error)
        }
    }
    
    // Método para guardar el mensaje en Firestore
    private func saveMessageToFirestore(message: String, recipients: [EmployeeCodable]) async throws -> Result<Void, Error> {
        guard let userId = UserManager.shared.employeeId else {
            throw NSError(domain: "EmployeeMessaging", code: 401, userInfo: [NSLocalizedDescriptionKey: "No hay usuario autenticado"])
        }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Crear un documento principal para el mensaje
        let messageRef = db.collection("messages").document()
        let messageId = messageRef.documentID
        
        let messageData: [String: Any] = [
            "message": message,
            "senderId": userId,
            "senderName":  "Administrador",
            "timestamp": FieldValue.serverTimestamp(),
            "status": "pending",
            "totalRecipients": recipients.count
        ]
        
        batch.setData(messageData, forDocument: messageRef)
        
        // Crear documentos para cada destinatario
        for recipient in recipients {
            let recipientRef = db.collection("messages").document(messageId).collection("recipients").document("\(recipient.id)")
            
            let recipientData: [String: Any] = [
                "recipientId": recipient.id,
                "recipientName": recipient.name,
                "recipientPhone": recipient.phone,
                "status": "pending",
                "timestamp": FieldValue.serverTimestamp()
            ]
            
            batch.setData(recipientData, forDocument: recipientRef)
        }
        
        // Ejecutar el batch
        try await batch.commit()
        
        print("Mensaje guardado en Firestore con ID: \(messageId)")
        print("Destinatarios: \(recipients.count)")
        
        self.isSending = false
        return .success(())
    }
    
    // Método para simular el envío de mensajes
    func simulateSendMessage(_ message: String) async -> Result<Void, Error> {
        self.isSending = true
        
        do {
            // Obtener los empleados seleccionados
            let selectedEmployeesList = employees.filter { selectedEmployees.contains($0.id) }
            
            // Simular tiempo de procesamiento
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 segundos
            
            // Registrar información en la consola
            print("Simulación: Mensaje enviado a \(selectedEmployeesList.count) empleados")
            for employee in selectedEmployeesList {
                print("  - Mensaje a: \(employee.name) (\(employee.phone))")
            }
            print("  - Contenido del mensaje: \"\(message)\"")
            
            // Registrar detalles del mensaje sin acceder a Firebase
            logMessageDetails(message: message, recipients: selectedEmployeesList)
            
            self.isSending = false
            return .success(())
        } catch {
            self.isSending = false
            return .failure(error)
        }
    }
    
    // Método para registrar detalles del mensaje sin acceder a Firebase
    private func logMessageDetails(message: String, recipients: [EmployeeCodable]) {
        // Registrar información básica sin intentar acceder a Firebase
        print("Registro de mensaje:")
        print("  - Total destinatarios: \(recipients.count)")
        
        for employee in recipients {
            let messageData: [String: Any] = [
                "message": message,
                "recipientId": employee.id,
                "recipientName": employee.name,
                "recipientPhone": employee.phone,
                "timestamp": Date().timeIntervalSince1970,
                "status": "pending",
                "sender": "admin"
            ]
            
            print("  - Datos para \(employee.name): \(messageData)")
        }
    }
}

// Estructura para decodificar la respuesta de token (para implementación real)
struct TokenResponse: Decodable {
    let token: String
}

struct EmployeeMessagingView_Previews: PreviewProvider {
    static var previews: some View {
        EmployeeMessagingView()
    }
} 
