//
//  EmployeeListView.swift
//  QGS
//
//  Created by Anwar Sarmiento on 2/27/25.
//

import SwiftUI

struct EmployeeListView: View {
    @StateObject private var viewModel = EmployeesViewModel()
    @State private var searchText = ""
    @State private var selectedEmployee: EmployeeCodable?
    @State private var showingDetail = false
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
                if !hasAccess {
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
                        .padding()}
                } else if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    SearchBar(text: $searchText)
                    
                    List {
                        ForEach(filteredEmployees) { employee in
                            EmployeeRow(employee: employee, onEditTap: {
                                selectedEmployee = employee
                                showingDetail = true
                            })
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await viewModel.fetchEmployees()
                    }
                }
            }
            .navigationTitle("Empleados")
            .onAppear {
                // Verificar acceso al aparecer la vista
                hasAccess = EmployeeListView.userHasAccess()
                
                // Solo cargar datos si tiene acceso
                if hasAccess && viewModel.employees.isEmpty {
                    Task {
                        await viewModel.fetchEmployees()
                    }
                }
            }
            .sheet(isPresented: $showingDetail, onDismiss: {
                Task {
                    await viewModel.fetchEmployees()
                }
            }) {
                if let employee = selectedEmployee {
                    EmployeeDetailView(employee: employee)
                }
            }
        }
    }
}

struct EmployeeRow: View {
    let employee: EmployeeCodable
    let onEditTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(employee.name)
                    .font(.headline)
                
                Spacer()
                
                // Mostrar el código del usuario
                if let code = employee.user?.code {
                    Text("Código: \(code)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                // Botón de editar
                Button(action: onEditTap) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                        .padding(.leading, 8)
                }
            }
            
            HStack {
                Text(employee.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Mostrar el estado
                Circle()
                    .fill(employee.status == 1 ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(employee.status == 1 ? "Activo" : "Inactivo")
                    .font(.caption)
                    .foregroundColor(employee.status == 1 ? .green : .red)
            }
            
            HStack {
                // Botón para llamar al número de teléfono
                Button(action: {
                    callPhoneNumber(employee.phone)
                }) {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.blue)
                        Text(employee.phone)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .underline()
                    }
                }
                .buttonStyle(BorderlessButtonStyle()) // Esto evita que el tap se propague a la fila
                
                Spacer()
                
                // Mostrar el tipo de trabajo
                if let workTypeName = employee.typeWork?.workType?.name {
                    Text(workTypeName)
                        .font(.caption)
                        .padding(4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // Función para llamar al número de teléfono
    private func callPhoneNumber(_ phoneNumber: String) {
        let cleanedPhoneNumber = phoneNumber.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        if let url = URL(string: "tel://\(cleanedPhoneNumber)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            TextField("Buscar...", text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        if !text.isEmpty {
                            Button(action: {
                                text = ""
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
        }
        .padding(.horizontal)
    }
}

struct EmployeeListView_Previews: PreviewProvider {
    static var previews: some View {
        EmployeeListView()
    }
}

