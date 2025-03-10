import SwiftUI
import Foundation


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
