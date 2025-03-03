import SwiftUI
import Foundation

// Definición local del ViewModel en caso de que no se pueda importar
class EmployeeDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var workTypes: [WorkType] = []
    
    enum EmployeeUpdateError: Error, LocalizedError {
        case networkError(String)
        case serverError(Int, String)
        case decodingError
        case invalidData
        
        var errorDescription: String? {
            switch self {
            case .networkError(let message):
                return NSLocalizedString("Error de red: \(message)", comment: "")
            case .serverError(let code, let message):
                return NSLocalizedString("Error del servidor (\(code)): \(message)", comment: "")
            case .decodingError:
                return NSLocalizedString("Error al procesar la respuesta del servidor", comment: "")
            case .invalidData:
                return NSLocalizedString("Datos inválidos", comment: "")
            }
        }
    }
    
    func fetchWorkTypes(completion: @escaping ([WorkType]) -> Void) {
        // Aquí podrías implementar una llamada a la API para obtener los tipos de trabajo
        // Por ahora, usaremos datos estáticos basados en el JSON proporcionado
        let workTypes = [
            WorkType(id: 1, name: "All Works", createdAt: nil, updatedAt: nil),
            WorkType(id: 2, name: "Sheetrock", createdAt: nil, updatedAt: nil),
            WorkType(id: 3, name: "Drywall", createdAt: nil, updatedAt: nil),
            WorkType(id: 4, name: "Finiship", createdAt: nil, updatedAt: nil),
            WorkType(id: 5, name: "Remodelacion", createdAt: nil, updatedAt: nil)
        ]
        
        DispatchQueue.main.async {
            self.workTypes = workTypes
            completion(workTypes)
        }
    }
    
    func updateEmployee(id: Int, name: String, email: String, phone: String, status: Int, workTypeId: Int, userEmail: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // Validar datos
        guard !name.isEmpty, !email.isEmpty, !phone.isEmpty else {
            isLoading = false
            errorMessage = NSLocalizedString("Todos los campos son obligatorios", comment: "")
            completion(.failure(EmployeeUpdateError.invalidData))
            return
        }
        
        Task {
            do {
                let url = URL(string: "https://api.friendlypayroll.net/api/colaboradores/update-employee/\(id)")!
                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                
                // Obtener el token de autenticación
                if let token = UserManager.shared.authToken {
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                } else {
                    throw EmployeeUpdateError.networkError(NSLocalizedString("No hay token de autenticación", comment: ""))
                }
                
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                // Crear el cuerpo de la solicitud
                let parameters: [String: Any] = [
                    "name": name,
                    "email": email,
                    "phone": phone,
                    "status": status,
                    "work_type_id": workTypeId,
                    "user_email": userEmail
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
                
                // Realizar la solicitud
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Validar el código de estado HTTP
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw EmployeeUpdateError.networkError(NSLocalizedString("Respuesta inválida del servidor", comment: ""))
                }
                
                if httpResponse.statusCode != 200 {
                    // Intentar obtener el mensaje de error del servidor
                    if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = errorJson["message"] as? String {
                        throw EmployeeUpdateError.serverError(httpResponse.statusCode, message)
                    } else {
                        throw EmployeeUpdateError.serverError(httpResponse.statusCode, NSLocalizedString("Error desconocido", comment: ""))
                    }
                }
                
                // Éxito
                completion(.success(()))
                
            } catch {
                self.errorMessage = error.localizedDescription
                completion(.failure(error))
            }
            
            self.isLoading = false
        }
    }
}

struct EmployeeDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = EmployeeDetailViewModel()
    
    let employee: EmployeeCodable
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var isActive: Bool = true
    @State private var selectedWorkTypeId: Int = 1
    @State private var userEmail: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Encabezado
                HStack {
                    Text(NSLocalizedString("ID: ", comment: "")) + Text("\(employee.id)")
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text(NSLocalizedString("Cédula: ", comment: "")) + Text(employee.card)
                        .fontWeight(.bold)
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom, 10)
                
                // Código de usuario
                if let userCode = employee.user?.code {
                    HStack {
                        Text(NSLocalizedString("Código: ", comment: "")) + Text(userCode)
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.bottom, 10)
                }
                
                // Campos de edición
                Group {
                    Text(NSLocalizedString("Nombre", comment: ""))
                        .font(.headline)
                    
                    TextField(NSLocalizedString("Nombre completo", comment: ""), text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.bottom, 10)
                    
                    Text(NSLocalizedString("Correo electrónico", comment: ""))
                        .font(.headline)
                    
                    TextField(NSLocalizedString("Correo electrónico", comment: ""), text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(.bottom, 10)
                    
                    Text(NSLocalizedString("Correo electrónico de usuario", comment: ""))
                        .font(.headline)
                    
                    TextField(NSLocalizedString("Correo electrónico de usuario", comment: ""), text: $userEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(.bottom, 10)
                    
                    Text(NSLocalizedString("Teléfono", comment: ""))
                        .font(.headline)
                    
                    TextField(NSLocalizedString("Número de teléfono", comment: ""), text: $phone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                        .padding(.bottom, 10)
                    
                    Text(NSLocalizedString("Tipo de trabajo", comment: ""))
                        .font(.headline)
                    
                    Picker(NSLocalizedString("Seleccione el tipo de trabajo", comment: ""), selection: $selectedWorkTypeId) {
                        ForEach(viewModel.workTypes, id: \.id) { workType in
                            Text(workType.name).tag(workType.id)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.bottom, 10)
                    
                    Toggle(NSLocalizedString("Activo", comment: ""), isOn: $isActive)
                        .padding(.bottom, 20)
                }
                
                // Botón de guardar
                Button(action: saveEmployee) {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .foregroundColor(.white)
                        } else {
                            Text(NSLocalizedString("Guardar cambios", comment: ""))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .disabled(viewModel.isLoading)
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.top, 10)
                }
            }
            .padding()
            .onAppear {
                // Inicializar los campos con los datos del empleado
                name = employee.name
                email = employee.email
                phone = employee.phone
                isActive = employee.status == 1
                selectedWorkTypeId = employee.typeWork?.workTypeId ?? 1
                userEmail = employee.user?.email ?? ""
                
                // Cargar los tipos de trabajo
                viewModel.fetchWorkTypes { _ in }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(isSuccess ? NSLocalizedString("Éxito", comment: "") : NSLocalizedString("Error", comment: "")),
                    message: Text(alertMessage),
                    dismissButton: .default(Text(NSLocalizedString("OK", comment: ""))) {
                        if isSuccess {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
        }
        .navigationTitle(NSLocalizedString("Editar Empleado", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func saveEmployee() {
        let status = isActive ? 1 : 0
        
        viewModel.updateEmployee(
            id: employee.id,
            name: name,
            email: email,
            phone: phone,
            status: status,
            workTypeId: selectedWorkTypeId,
            userEmail: userEmail
        ) { result in
            switch result {
            case .success:
                alertMessage = NSLocalizedString("Información actualizada correctamente", comment: "")
                isSuccess = true
                showingAlert = true
            case .failure(let error):
                alertMessage = error.localizedDescription
                isSuccess = false
                showingAlert = true
            }
        }
    }
}

#Preview {
    NavigationView {
        EmployeeDetailView(employee: EmployeeCodable(
            id: 1,
            card: "123456789",
            typeOfCard: "01",
            name: "Nombre Ejemplo",
            vacation: 0,
            email: "ejemplo@email.com",
            phone: "123-456-7890",
            address: "Dirección de ejemplo",
            provinceId: nil,
            cantonId: nil,
            districtId: nil,
            maritalStatusId: nil,
            nationalityId: nil,
            userId: 1,
            status: 1,
            createdAt: nil,
            updatedAt: nil,
            typeWork: TypeWork(
                id: 1,
                employeeId: 1,
                workTypeId: 3,
                createdAt: nil,
                updatedAt: nil,
                workType: WorkType(
                    id: 3,
                    name: "Drywall",
                    createdAt: nil,
                    updatedAt: nil
                )
            ),
            user: User(
                id: 1,
                name: "Nombre Usuario",
                type: "employee",
                sysconfId: 2,
                code: "10001",
                email: "usuario@email.com",
                emailVerifiedAt: nil,
                createdAt: nil,
                updatedAt: nil
            )
        ))
    }
} 
