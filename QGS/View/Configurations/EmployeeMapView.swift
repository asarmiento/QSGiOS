import SwiftUI
import MapKit
import CoreLocation

// Definición del modelo EmployeeLocation aquí para asegurar que esté disponible
struct EmployeeLocation: Codable, Identifiable {
    let employeeName: String
    let latitude: String
    let longitude: String
    let entryTime: String
    let projectName: String
    
    var id: String { employeeName }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: Double(latitude) ?? 0.0,
            longitude: Double(longitude) ?? 0.0
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case employeeName = "employee_name"
        case latitude
        case longitude
        case entryTime = "entry_time"
        case projectName = "project_name"
    }
}

// ViewModel definido aquí para asegurar que esté disponible
@MainActor
class EmployeeLocationViewModel: ObservableObject {
    @Published var employeeLocations: [EmployeeLocation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.769484, longitude: -84.071002),
        span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
    )
    @Published var mapPosition: MapCameraPosition = .automatic
    
    func fetchEmployeeLocations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let token = UserManager.shared.authToken else {
                errorMessage = "No hay token de autenticación"
                isLoading = false
                return
            }
            
            let url = URL(string: "https://api.friendlypayroll.net/api/projects/employee-location-job")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            if httpResponse.statusCode == 200 {
                let locations = try JSONDecoder().decode([EmployeeLocation].self, from: data)
                self.employeeLocations = locations
                
                if let firstLocation = locations.first {
                    self.region = MKCoordinateRegion(
                        center: firstLocation.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
                    )
                    self.mapPosition = .region(self.region)
                }
            } else {
                throw URLError(.badServerResponse)
            }
        } catch {
            errorMessage = "Error al cargar las ubicaciones: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct EmployeeMapView: View {
    @StateObject private var viewModel = EmployeeLocationViewModel()
    @State private var selectedEmployee: EmployeeLocation?
    @State private var showingEmployeeInfo = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if #available(iOS 17.0, *) {
                    Map(position: $viewModel.mapPosition) {
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