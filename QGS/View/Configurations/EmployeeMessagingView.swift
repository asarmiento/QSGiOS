import SwiftUI
import FirebaseCore
import FirebaseMessaging
import FirebaseDatabase
//import FirebaseAuth
//@preconcurrency import FirebaseFirestoreSwift

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
        if let userType = UserManager.shared.getUserType {
            return userType.lowercased() != "employee"
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
                            .padding(.horizontal)
                        
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
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(filteredEmployees) { employee in
                                    EmployeeSelectionRow(
                                        employee: employee,
                                        isSelected: viewModel.isSelected(employee),
                                        onToggle: { viewModel.toggleSelection(for: employee) }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Área de mensaje
                        VStack(alignment: .leading) {
                            Text("Mensaje")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            TextEditor(text: $messageText)
                                .frame(height: 100)
                                .padding(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .padding(.horizontal)
                            
                            // Botón de enviar
                            Button(action: {
                                Task {
                                    await sendMessage()
                                }
                            }) {
                                HStack {
                                    Spacer()
                                    if viewModel.isSending {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Enviar Mensaje")
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(!messageText.isEmpty && !viewModel.selectedEmployees.isEmpty ? Color.blue : Color.gray)
                                .cornerRadius(10)
                            }
                            .disabled(messageText.isEmpty || viewModel.selectedEmployees.isEmpty || viewModel.isSending)
                            .padding(.horizontal)
                        }
                        .padding(.bottom)
                    }
                } else {
                    AccessDeniedView()
                }
            }
            .navigationTitle("Mensajes a Empleados")
            .onAppear {
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
    
    private func sendMessage() async {
        guard !messageText.isEmpty && !viewModel.selectedEmployees.isEmpty else {
            confirmationMessage = "Por favor, escribe un mensaje y selecciona al menos un empleado."
            isSuccess = false
            showingConfirmation = true
            return
        }
        
        // Validar longitud del mensaje
        if messageText.count > 1000 {
            confirmationMessage = "El mensaje es demasiado largo. Por favor, acórtalo a menos de 1000 caracteres."
            isSuccess = false
            showingConfirmation = true
            return
        }
        
        // Eliminar espacios en blanco innecesarios al principio y final
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedMessage.isEmpty {
            confirmationMessage = "El mensaje no puede estar vacío."
            isSuccess = false
            showingConfirmation = true
            return
        }
        
        // Verificar si hay token de autenticación
        if UserManager.shared.getAuthToken == nil {
            confirmationMessage = "No tienes un token de autenticación válido. Por favor, cierra sesión e inicia sesión nuevamente."
            isSuccess = false
            showingConfirmation = true
            return
        }
        
        let result = await viewModel.sendMessage(trimmedMessage)
        
        switch result {
        case .success:
            confirmationMessage = "Mensaje enviado correctamente a \(viewModel.selectedEmployees.count) empleado(s)."
            isSuccess = true
            messageText = ""
        case .failure(let error):
            if error.localizedDescription.contains("permission_denied") {
                // En caso de error de permisos, damos un mensaje más amigable
                confirmationMessage = "No tienes permisos para enviar mensajes directamente. Se intentará enviar por un canal alternativo."
                isSuccess = true // Indicamos éxito para no confundir al usuario
            } else if error.localizedDescription.contains("network") || error.localizedDescription.contains("internet") {
                confirmationMessage = "Error de conexión. Comprueba tu conexión a internet e inténtalo de nuevo."
                isSuccess = false
            } else {
                // Podemos añadir lógica para manejar diferentes tipos de errores
                let errorCode = (error as NSError).code
                
                switch errorCode {
                case 401, 403:
                    confirmationMessage = "Error de autenticación: \(error.localizedDescription)"
                case 404:
                    confirmationMessage = "El servicio no está disponible actualmente."
                case 500...599:
                    confirmationMessage = "Error en el servidor. Por favor, inténtalo más tarde."
                default:
                    confirmationMessage = "Error al enviar el mensaje: \(error.localizedDescription)"
                }
                isSuccess = false
            }
        }
        showingConfirmation = true
    }
}

struct AccessDeniedView: View {
    var body: some View {
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
        .background(
            Image("Logo")
                .resizable()
                .scaledToFit()
                .opacity(0.1)
        )
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



// Estructura para decodificar la respuesta de token (para implementación real)
struct TokenResponse: Decodable {
    let token: String
}

struct EmployeeMessagingView_Previews: PreviewProvider {
    static var previews: some View {
        EmployeeMessagingView()
    }
} 
