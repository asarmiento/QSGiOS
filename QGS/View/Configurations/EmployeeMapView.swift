import SwiftUI
import MapKit
import CoreLocation



struct EmployeeMapView: View {
    @StateObject private var viewModel = EmployeeLocationViewModel()
    @State private var selectedEmployee: EmployeeLocation?
    @State private var showingEmployeeInfo = false
    @State private var position: MapCameraPosition = .automatic
    

    
    var body: some View {
        NavigationView {
            ZStack {
                if #available(iOS 17.0, *) {
                    // Usamos una propiedad de estado local que se actualiza con la región del ViewModel
                    Map(position: $position) {
                        ForEach(viewModel.employeeLocations) { location in
                            Annotation(location.employeeName, coordinate: location.coordinate) {
                                Button(action: {
                                    selectedEmployee = location
                                    showingEmployeeInfo = true
                                }) {
                                    VStack {
                                        Image(systemName: "person.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.blue)
                                        
                                        Text(location.employeeName)
                                            .font(.caption)
                                            .padding(4)
                                            .background(Color.white.opacity(0.8))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                    }
                    .onAppear {
                        // Actualizar la posición cuando cambia la región
                        position = viewModel.mapCameraPosition
                    }
                    .onChange(of: "\(viewModel.region.center.latitude),\(viewModel.region.center.longitude)") { _, _ in
                        position = viewModel.mapCameraPosition
                    }
                } else {
                    Map(coordinateRegion: $viewModel.region,
                        annotationItems: viewModel.employeeLocations) { location in
                        MapAnnotation(coordinate: location.coordinate) {
                            VStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.blue)
                                    .onTapGesture {
                                        selectedEmployee = location
                                        showingEmployeeInfo = true
                                    }
                                
                                Text(location.employeeName)
                                    .font(.caption)
                                    .padding(4)
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Ubicación de Empleados")
            .sheet(isPresented: $showingEmployeeInfo) {
                if let employee = selectedEmployee {
                    EmployeeInfoView(employee: employee)
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchEmployeeLocations()
                }
            }
            .refreshable {
                await viewModel.fetchEmployeeLocations()
            }
        }
    }
}

struct EmployeeInfoView: View {
    let employee: EmployeeLocation
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    
                    Text(employee.employeeName)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    InfoRow(icon: "clock.fill", title: "Hora de entrada", value: employee.entryTime)
                    InfoRow(icon: "building.2.fill", title: "Proyecto", value: employee.projectName)
                    InfoRow(icon: "location.fill", title: "Coordenadas", value: String(format: "%.6f, %.6f", Double(employee.latitude) ?? 0, Double(employee.longitude) ?? 0))
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cerrar") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.body)
            }
        }
    }
}

struct EmployeeMapView_Previews: PreviewProvider {
    static var previews: some View {
        EmployeeMapView()
    }
} 
