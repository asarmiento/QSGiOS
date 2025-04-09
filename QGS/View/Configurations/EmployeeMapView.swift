import SwiftUI
import MapKit
import CoreLocation

// Modelo para la ubicación de un empleado
struct EmployeeLocationData: Identifiable {
    let id: String
    let employeeName: String
    let projectName: String
    let entryTime: String
    let latitude: String
    let longitude: String
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: Double(latitude) ?? 0,
            longitude: Double(longitude) ?? 0
        )
    }
}

// Clase auxiliar para manejar la búsqueda
class SearchHandler: NSObject, MKLocalSearchCompleterDelegate, ObservableObject {
    @Published var searchResults: [MKLocalSearchCompletion] = []
    var searchCompleter = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
    }
    
    func search(query: String) {
        if !query.isEmpty {
            searchCompleter.queryFragment = query
        }
    }
    
    // Implementación de los métodos del delegado
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.searchResults = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error en la búsqueda: \(error.localizedDescription)")
    }
}

struct EmployeeMapView: View {
    @StateObject private var viewModel = EmployeeLocationViewModel()
    @StateObject private var searchHandler = SearchHandler()
    @State private var selectedEmployee: EmployeeLocationData?
    @State private var showingEmployeeInfo = false
    @State private var position: MapCameraPosition = .automatic
    @State private var hasAccess: Bool = false
    @State private var searchText = ""
    @State private var showingSearchResults = false
    
    // Función estática para verificar si el usuario tiene acceso
    static func userHasAccess() -> Bool {
        // Verificar si el tipo de usuario no es "employee"
        if let userType = UserManager.shared.getUserType {
            return userType.lowercased() != "employee"
        }
        return false
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if hasAccess {
                    VStack(spacing: 0) {
                        // Buscador de ubicaciones
                        searchBarView
                        
                        // Contenido del mapa
                        mapContentView
                    }
                } else {
                    
                        accessDeniedView
                }
            }
            .navigationTitle("Ubicación de Empleados")
            .sheet(isPresented: $showingEmployeeInfo) {
                if let employee = selectedEmployee {
                    EmployeeInfoView(employee: employee)
                }
            }
            .onAppear {
                // Verificar si el usuario tiene acceso
                checkUserAccess()
                hasAccess = EmployeeMapView.userHasAccess()
                
                if hasAccess {
                    Task {
                        await viewModel.fetchEmployeeLocations()
                    }
                }
            }
            .refreshable {
                if hasAccess {
                    await viewModel.fetchEmployeeLocations()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Mejor compatibilidad con iPad
    }
    
    // Vista de la barra de búsqueda
    private var searchBarView: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Buscar ubicación", text: $searchText)
                    .onChange(of: searchText) { oldValue, newValue in
                        searchHandler.search(query: newValue)
                        showingSearchResults = !newValue.isEmpty
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        showingSearchResults = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            if showingSearchResults && !searchHandler.searchResults.isEmpty {
                searchResultsListView
            }
        }
        .padding(.top)
        .background(Color.white)
        .zIndex(1)
    }
    
    // Vista de la lista de resultados de búsqueda
    private var searchResultsListView: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(searchHandler.searchResults, id: \.self) { result in
                    Button(action: {
                        searchLocation(result)
                        searchText = result.title
                        showingSearchResults = false
                    }) {
                        VStack(alignment: .leading) {
                            Text(result.title)
                                .foregroundColor(.primary)
                            if !result.subtitle.isEmpty {
                                Text(result.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
            }
            .padding(.horizontal)
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal)
        .frame(height: 200)
    }
    
    // Vista del contenido del mapa
    private var mapContentView: some View {
        ZStack {
            if #available(iOS 17.0, macOS 14.0, *) {
                // Mapa para iOS 17+ y macOS 14+
                Map(position: $position) {
                    ForEach(viewModel.employeeLocations) { location in
                        Annotation(location.employeeName, coordinate: location.coordinate) {
                            employeeAnnotationView(for: location)
                        }
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                .onAppear {
                    position = viewModel.mapCameraPosition
                }
                .onChange(of: viewModel.region.center.latitude) { oldValue, newValue in
                    position = viewModel.mapCameraPosition
                }
                .onChange(of: viewModel.region.center.longitude) { oldValue, newValue in
                    position = viewModel.mapCameraPosition
                }
            } else {
                // Mapa para iOS < 17 y macOS < 14
                Map(coordinateRegion: $viewModel.region,
                    showsUserLocation: true,
                    annotationItems: viewModel.employeeLocations) { location in
                    // Usar MapAnnotation de SwiftUI, no nuestra estructura personalizada
                    MapKit.MapAnnotation(coordinate: location.coordinate) {
                        employeeAnnotationView(for: location)
                    }
                }
            }
            
            // Indicador de carga
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
            }
            
            // Mensaje de error
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // Vista de acceso denegado
    private var accessDeniedView: some View {
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
    
    // Vista de anotación para empleados
    private func employeeAnnotationView(for location: EmployeeLocationData) -> some View {
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
    
    private func checkUserAccess() {
        // Verificar el tipo de usuario desde UserManager
        if let userType = UserManager.shared.getUserType {
            // Si el usuario es administrador o supervisor, tiene acceso
            hasAccess = userType.lowercased() != "empleado"
        } else {
            hasAccess = false
        }
    }
    
    private func searchLocation(_ result: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            guard let response = response, let item = response.mapItems.first else {
                return
            }
            
            let coordinate = item.placemark.coordinate
            
            // Actualizar la región del mapa
            let region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            
            viewModel.region = region
            
            if #available(iOS 17.0, macOS 14.0, *) {
                position = .region(region)
            }
        }
    }
}

struct EmployeeInfoView: View {
    let employee: EmployeeLocationData
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
