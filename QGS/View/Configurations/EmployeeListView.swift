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
    
    var body: some View {
        ZStack {
            // Marca de agua
            Image("QGS-Branding-01")
                .resizable()
                .scaledToFit()
                .opacity(0.1)
            
            VStack {
                // Barra de búsqueda
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                if viewModel.isLoading {
                    ProgressView(NSLocalizedString("Cargando empleados...", comment: ""))
                } else if let error = viewModel.errorMessage {
                    ErrorEmployeeView(message: error)
                } else {
                    List(filteredEmployees, id: \.id) { employee in
                        EmployeeRow(employee: employee)
                    }
                    .refreshable {
                        viewModel.fetchEmployees()
                    }
                }
            }
        }
        .navigationTitle(NSLocalizedString("Empleados", comment: ""))
        .onAppear {
            viewModel.fetchEmployees()
        }
    }
    
    // Filtrar empleados según el texto de búsqueda
    private var filteredEmployees: [EmployeeCodable] {
        if searchText.isEmpty {
            return viewModel.employees
        } else {
            return viewModel.employees.filter { employee in
                employee.name.localizedCaseInsensitiveContains(searchText) ||
                employee.email.localizedCaseInsensitiveContains(searchText) ||
                employee.phone.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct EmployeeRow: View {
    let employee: EmployeeCodable
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(employee.name)
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label(employee.email, systemImage: "envelope")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Label(employee.phone, systemImage: "phone")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Indicador de estado (activo/inactivo)
                if employee.status == 1 {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                } else {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                }
            }
            
            Divider()
        }
        .padding(.vertical, 8)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(NSLocalizedString("Buscar empleado...", comment: ""), text: $text)
                .foregroundColor(.primary)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}

struct ErrorEmployeeView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.red)
        }
        .padding()
    }
}

#Preview {
    NavigationView {
        EmployeeListView()
    }
}

