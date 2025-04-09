import SwiftUI
import MapKit
import CoreLocation

// ViewModel para la vista de editar proyecto
@preconcurrency
@MainActor
class EditProjectViewModel: NSObject, ObservableObject, URLSessionTaskDelegate, URLSessionDataDelegate {
    @Published var projectName = ""
    @Published var budget = ""
    @Published var isActive = true
    @Published var projectId: Int = 0
    @Published var address = "" // Añadimos para mostrar la dirección aunque no se edite
    
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var projectSaved = false
    
    private var urlSession: URLSession!
    private var activeDataTasks: Set<URLSessionDataTask> = []
    
    override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForResource = 30 // 30 segundos de timeout
        configuration.waitsForConnectivity = true
        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    deinit {
        // Cancelar todas las tareas de URLSession activas
        for task in activeDataTasks {
            task.cancel()
        }
        activeDataTasks.removeAll()
        
        // Invalidar la sesión
        urlSession.invalidateAndCancel()
    }
    
    func cancelAllTasks() {
        // Cancelar todas las tareas de URLSession activas
        activeDataTasks.forEach { $0.cancel() }
        activeDataTasks.removeAll()
    }
    
    // Delegado de URLSession para manejar la finalización de tareas
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let dataTask = task as? URLSessionDataTask {
            Task { @MainActor in
                self.activeDataTasks.remove(dataTask)
            }
        }
    }
    
    var canSave: Bool {
        return !projectName.isEmpty && !budget.isEmpty
    }
    
    func loadProject(id: Int) async {
        isLoading = true
        
        do {
            guard let token = UserManager.shared.getAuthToken else {
                throw NSError(domain: "EditProject", code: 401, userInfo: [NSLocalizedDescriptionKey: "No hay token de autenticación"])
            }
            
            let url = URL(string: "https://api.friendlypayroll.net/api/projects/show-data-project/\(id)")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw NSError(domain: "EditProject", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "Error al cargar el proyecto"])
            }
            
            // Intentar decodificar como un diccionario
            if let jsonDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                await MainActor.run {
                    if let id = jsonDict["id"] as? Int {
                        self.projectId = id
                    }
                    
                    if let name = jsonDict["name"] as? String {
                        self.projectName = name
                    }
                    
                    if let address = jsonDict["address"] as? String {
                        self.address = address
                    }
                    
                    if let budget = jsonDict["budget"] as? Double {
                        self.budget = String(format: "%.2f", budget)
                    } else if let budgetString = jsonDict["budget"] as? String, let budgetValue = Double(budgetString) {
                        self.budget = String(format: "%.2f", budgetValue)
                    } else {
                        self.budget = "0.00"
                    }
                    
                    if let status = jsonDict["status"] as? Bool {
                        self.isActive = status
                    } else if let statusInt = jsonDict["status"] as? Int {
                        self.isActive = statusInt == 1
                    } else {
                        self.isActive = true
                    }
                    
                    self.isLoading = false
                }
            } else {
                throw NSError(domain: "EditProject", code: 422, userInfo: [NSLocalizedDescriptionKey: "Error al decodificar los datos del proyecto"])
            }
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.alertTitle = "Error"
                self.alertMessage = "Error al cargar el proyecto: \(error.localizedDescription)"
                self.showAlert = true
            }
        }
    }
    
    func saveProject() async {
        guard canSave else {
            alertTitle = "Error"
            alertMessage = "Por favor, completa todos los campos requeridos."
            showAlert = true
            return
        }
        
        isLoading = true
        
        do {
            guard let token = UserManager.shared.getAuthToken else {
                throw NSError(domain: "EditProject", code: 401, userInfo: [NSLocalizedDescriptionKey: "No hay token de autenticación"])
            }
            
            let url = URL(string: "https://api.friendlypayroll.net/api/projects/update-data-project/\(projectId)")!
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Convertir el presupuesto a Double si es posible
            let budgetValue = Double(budget.replacingOccurrences(of: ",", with: ".")) ?? 0.0
            
            let projectData: [String: Any] = [
                "name": projectName,
                "budget": budgetValue,
                "status": isActive
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: projectData)
            request.httpBody = jsonData
            
            // Crear una tarea y guardarla en activeDataTasks
            let dataTask = urlSession.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }
                
                Task { @MainActor in
                    self.isLoading = false
                    
                    if let error = error {
                        self.alertTitle = "Error"
                        self.alertMessage = "Error al actualizar el proyecto: \(error.localizedDescription)"
                        self.showAlert = true
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        self.alertTitle = "Error"
                        self.alertMessage = "Error: Respuesta del servidor inválida"
                        self.showAlert = true
                        return
                    }
                    
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                        self.projectSaved = true
                        self.alertTitle = "Éxito"
                        self.alertMessage = "El proyecto ha sido actualizado correctamente."
                    } else {
                        if let data = data, let responseString = String(data: data, encoding: .utf8) {
                            self.alertTitle = "Error"
                            self.alertMessage = "Error al actualizar el proyecto: \(responseString)"
                        } else {
                            self.alertTitle = "Error"
                            self.alertMessage = "Error al actualizar el proyecto. Código: \(httpResponse.statusCode)"
                        }
                        self.showAlert = true
                    }
                }
            }
            
            // Registrar la tarea activa
            activeDataTasks.insert(dataTask)
            
            // Iniciar la tarea
            dataTask.resume()
            
            // Esperar a que la tarea se complete (esto es necesario para el flujo async/await)
            await withCheckedContinuation { continuation in
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                    continuation.resume()
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.alertTitle = "Error"
                self.alertMessage = "Error al actualizar el proyecto: \(error.localizedDescription)"
                self.showAlert = true
            }
        }
    }
}

struct EditProjectView: View {
    @Binding var isPresented: Bool
    var projectId: Int
    var onProjectUpdated: () -> Void
    
    @StateObject private var viewModel = EditProjectViewModel()
    @State private var hasAccess: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if hasAccess {
                    Form {
                        Section(header: Text("Información del Proyecto")) {
                            TextField("Nombre del proyecto", text: $viewModel.projectName)
                                .padding(.vertical, 8)
                            
                            // Campo de presupuesto
                            HStack {
                                Text("Presupuesto")
                                    .font(.body)
                                
                                Spacer()
                                
                                TextField("0.00", text: $viewModel.budget)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 120)
                            }
                            .padding(.vertical, 8)
                            
                            // Mostrar la dirección (no editable)
                            VStack(alignment: .leading) {
                                Text("Dirección")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text(viewModel.address)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 8)
                            
                            // Toggle para el estado
                            Toggle("Proyecto Activo", isOn: $viewModel.isActive)
                                .padding(.vertical, 8)
                        }
                        
                        Section {
                            Button(action: {
                                Task {
                                    await viewModel.saveProject()
                                    if viewModel.projectSaved {
                                        onProjectUpdated()
                                        isPresented = false
                                    }
                                }
                            }) {
                                HStack {
                                    Spacer()
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .foregroundColor(.white)
                                    } else {
                                        Text("Guardar Cambios")
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(viewModel.canSave ? Color.blue : Color.gray)
                                .cornerRadius(10)
                            }
                            .disabled(!viewModel.canSave || viewModel.isLoading)
                            .listRowInsets(EdgeInsets())
                        }
                    }
                    
                    if viewModel.isLoading {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                        
                        ProgressView("Cargando...")
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                } else {
                    ZStack {
                        // Marca de agua
                        Image("Logo")
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
            .navigationTitle("Editar Proyecto")
            .navigationBarItems(
                trailing: Button("Cancelar") {
                    isPresented = false
                }
            )
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("Aceptar"))
                )
            }
            .onAppear {
                // Verificar si el usuario tiene acceso
                checkUserAccess()
                
                if hasAccess {
                    // Cargar los datos del proyecto
                    Task {
                        await viewModel.loadProject(id: projectId)
                    }
                }
            }
        }
    }
    
    private func checkUserAccess() {
        // Verificar el tipo de usuario desde UserManager
        if let user = UserManager.shared.getUser() {
            // Si el usuario es administrador o supervisor, tiene acceso
            hasAccess = user.type != "employee"
        } else {
            hasAccess = false
        }
    }
}

#Preview {
    EditProjectView(isPresented: .constant(true), projectId: 1, onProjectUpdated: {})
} 
