import SwiftUI
import MapKit
import CoreLocation

// Clase auxiliar para manejar la búsqueda de direcciones
class AddressSearchHandler: NSObject, MKLocalSearchCompleterDelegate, ObservableObject {
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var isSearching = false
    var searchCompleter = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
    }
    
    func search(query: String) {
        if !query.isEmpty {
            isSearching = true
            searchCompleter.queryFragment = query
        } else {
            isSearching = false
            searchResults = []
        }
    }
    
    // Implementación de los métodos del delegado
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.searchResults = completer.results
            self.isSearching = false
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error en la búsqueda: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isSearching = false
        }
    }
}

struct AddProjectView: View {
    @Binding var isPresented: Bool
    var onProjectAdded: () -> Void
    
    @StateObject private var viewModel = AddProjectViewModel()
    @StateObject private var searchHandler = AddressSearchHandler()
    @StateObject private var locationController = LocationViewController.shared // Usar LocationViewController existente
    @State private var searchText = ""
    @State private var showingSearchResults = false
    @State private var hasAccess: Bool = false
    @FocusState private var isSearchFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                if hasAccess {
                    VStack(spacing: 0) {
                        // Formulario para el nombre del proyecto
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
                                
                                VStack(alignment: .leading) {
                                    Text("Dirección")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    HStack {
                                        TextField("Buscar dirección", text: $searchText)
                                            .padding(.vertical, 8)
                                            .focused($isSearchFieldFocused)
                                            .onChange(of: searchText) { _, newValue in
                                                searchHandler.search(query: newValue)
                                                showingSearchResults = !newValue.isEmpty
                                            }
                                            .onSubmit {
                                                if !searchHandler.searchResults.isEmpty {
                                                    selectSearchResult(searchHandler.searchResults[0])
                                                    isSearchFieldFocused = false
                                                    showingSearchResults = false
                                                }
                                            }
                                        
                                        if searchHandler.isSearching {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle())
                                                .scaleEffect(0.7)
                                        } else if !searchText.isEmpty {
                                            Button(action: {
                                                searchText = ""
                                                showingSearchResults = false
                                                isSearchFieldFocused = false
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.gray)
                                            }
                                        } else {
                                            Button(action: {
                                                isSearchFieldFocused = true
                                            }) {
                                                Image(systemName: "magnifyingglass")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                }
                                
                                if viewModel.address.isEmpty {
                                    Text("Selecciona una ubicación en el mapa")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                } else {
                                    Text(viewModel.address)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            if showingSearchResults && !searchHandler.searchResults.isEmpty {
                                Section(header: Text("Resultados de búsqueda")) {
                                    ForEach(searchHandler.searchResults, id: \.self) { result in
                                        Button(action: {
                                            selectSearchResult(result)
                                            searchText = result.title
                                            showingSearchResults = false
                                            isSearchFieldFocused = false
                                        }) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(result.title)
                                                    .foregroundColor(.primary)
                                                    .font(.body)
                                                if !result.subtitle.isEmpty {
                                                    Text(result.subtitle)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            .padding(.vertical, 4)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: 300) // Aumentado para acomodar el nuevo campo
                        .onTapGesture {
                            // Cerrar el teclado y los resultados de búsqueda al tocar fuera
                            if isSearchFieldFocused || showingSearchResults {
                                isSearchFieldFocused = false
                                // Mantener los resultados visibles si hay texto
                                showingSearchResults = !searchText.isEmpty && !searchHandler.searchResults.isEmpty
                            }
                        }
                        
                        // Mapa para seleccionar ubicación
                        ZStack {
                            if #available(iOS 17.0, *) {
                                Map(position: $viewModel.position) {
                                    Marker("Ubicación seleccionada", coordinate: viewModel.coordinate)
                                        .tint(.red)
                                }
                                .mapControls {
                                    MapUserLocationButton()
                                    MapCompass()
                                    MapScaleView()
                                }
                                .onTapGesture { location in
                                    // Cerrar el teclado y los resultados de búsqueda
                                    isSearchFieldFocused = false
                                    showingSearchResults = false
                                    
                                    // Manejar el tap en el mapa
                                    viewModel.handleMapTap(viewModel.coordinate)
                                }
                            } else {
                                Map(coordinateRegion: $viewModel.region, showsUserLocation: true, annotationItems: [viewModel.annotation]) { annotation in
                                    MapMarker(coordinate: annotation.coordinate, tint: .red)
                                }
                                .gesture(
                                    DragGesture()
                                        .onEnded { _ in
                                            // Cerrar el teclado y los resultados de búsqueda
                                            isSearchFieldFocused = false
                                            showingSearchResults = false
                                            
                                            viewModel.updateAddressFromRegion()
                                        }
                                )
                            }
                            
                            // Botón para centrar en la ubicación del usuario
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        // Cerrar el teclado y los resultados de búsqueda
                                        isSearchFieldFocused = false
                                        showingSearchResults = false
                                        
                                        // Convertir las coordenadas a Double
                                        let latitude = Double(locationController.latitude) ?? 9.9281
                                        let longitude = Double(locationController.longitude) ?? -84.0907
                                        
                                        let location = CLLocation(
                                            latitude: latitude,
                                            longitude: longitude
                                        )
                                        viewModel.centerOnUserLocation(location)
                                    }) {
                                        Image(systemName: "location.fill")
                                            .padding()
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .shadow(radius: 2)
                                    }
                                    .padding()
                                }
                            }
                        }
                        .edgesIgnoringSafeArea(.bottom)
                        
                        // Botón para guardar
                        VStack {
                            Button(action: {
                                // Cerrar el teclado y los resultados de búsqueda
                                isSearchFieldFocused = false
                                showingSearchResults = false
                                
                                Task {
                                    await viewModel.saveProject()
                                    if viewModel.projectSaved {
                                        onProjectAdded()
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
                                        Text("Guardar Proyecto")
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(viewModel.canSave ? Color.blue : Color.gray)
                                .cornerRadius(10)
                                .padding()
                            }
                            .disabled(!viewModel.canSave || viewModel.isLoading)
                        }
                    }
                    
                    if viewModel.isLoading {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                        
                        ProgressView("Guardando...")
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
            .navigationTitle("Nuevo Proyecto")
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
                    locationController.requestLocationPermission()
                    
                    // Convertir las coordenadas a Double
                    let latitude = Double(locationController.latitude) ?? 9.9281
                    let longitude = Double(locationController.longitude) ?? -84.0907
                    
                    let location = CLLocation(
                        latitude: latitude,
                        longitude: longitude
                    )
                    viewModel.centerOnUserLocation(location)
                }
            }
            .onTapGesture {
                // Cerrar el teclado y los resultados de búsqueda al tocar fuera
                isSearchFieldFocused = false
                showingSearchResults = false
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
    
    private func selectSearchResult(_ result: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)
        
        // Cancelar búsquedas anteriores si las hay
        search.start { response, error in
            guard let response = response, let item = response.mapItems.first else {
                // Asegurarse de liberar recursos incluso en caso de error
                search.cancel()
                return
            }
            
            let coordinate = item.placemark.coordinate
            
            // Actualizar en el hilo principal
            DispatchQueue.main.async { [viewModel] in
                viewModel.coordinate = coordinate
                
                // Usar la dirección formateada del placemark si está disponible
                let placemark = item.placemark
                let addressComponents = [
                    placemark.thoroughfare,
                    placemark.subThoroughfare,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.country
                ].compactMap { $0 }
                
                if !addressComponents.isEmpty {
                    viewModel.address = addressComponents.joined(separator: ", ")
                } else {
                    // Si no hay componentes de dirección, usar el título del resultado
                    viewModel.address = result.title
                }
                
                viewModel.annotation = MapAnnotation(coordinate: coordinate)
                
                // Actualizar región y posición
                let region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                viewModel.region = region
                
                if #available(iOS 17.0, *) {
                    viewModel.position = .region(region)
                }
            }
            
            // Liberar recursos explícitamente
            search.cancel()
        }
    }
}

// Modelo de anotación para el mapa
struct MapAnnotation: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}

// ViewModel para la vista de agregar proyecto
@preconcurrency
@MainActor
class AddProjectViewModel: NSObject, ObservableObject, URLSessionTaskDelegate, URLSessionDataDelegate {
    @Published var projectName = ""
    @Published var address = ""
    @Published var budget = "" // Nuevo campo para el presupuesto
    @Published var coordinate = CLLocationCoordinate2D(latitude: 9.9281, longitude: -84.0907) // Costa Rica por defecto
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 9.9281, longitude: -84.0907),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 9.9281, longitude: -84.0907),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))
    
    @Published var annotation = MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: 9.9281, longitude: -84.0907))
    
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var projectSaved = false
    
    private let geocoder = CLGeocoder()
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
        // Cancelar todas las tareas de geocodificación directamente
        geocoder.cancelGeocode()
        
        // Cancelar todas las tareas de URLSession activas
        for task in activeDataTasks {
            task.cancel()
        }
        activeDataTasks.removeAll()
        
        // Invalidar la sesión
        urlSession.invalidateAndCancel()
    }
    
    func cancelAllTasks() {
        // Cancelar todas las tareas de geocodificación
        geocoder.cancelGeocode()
        
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
        return !projectName.isEmpty && !address.isEmpty
    }
    
    func centerOnUserLocation(_ location: CLLocation) {
        coordinate = location.coordinate
        annotation = MapAnnotation(coordinate: coordinate)
        
        // Actualizar región y posición
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        if #available(iOS 17.0, *) {
            position = .region(region)
        }
        
        // Cancelar cualquier geocodificación anterior
        geocoder.cancelGeocode()
        
        // Obtener dirección
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self, let placemark = placemarks?.first else { return }
            
            DispatchQueue.main.async {
                self.address = [
                    placemark.thoroughfare,
                    placemark.subThoroughfare,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.country
                ].compactMap { $0 }.joined(separator: ", ")
            }
        }
    }
    
    func handleMapTap(_ coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self.annotation = MapAnnotation(coordinate: coordinate)
        
        // Cancelar cualquier geocodificación anterior
        geocoder.cancelGeocode()
        
        // Obtener dirección
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self, let placemark = placemarks?.first else { return }
            
            DispatchQueue.main.async {
                self.address = [
                    placemark.thoroughfare,
                    placemark.subThoroughfare,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.country
                ].compactMap { $0 }.joined(separator: ", ")
            }
        }
    }
    
    func updateAddressFromRegion() {
        // Para iOS < 17
        let location = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        coordinate = region.center
        annotation = MapAnnotation(coordinate: coordinate)
        
        // Cancelar cualquier geocodificación anterior
        geocoder.cancelGeocode()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self, let placemark = placemarks?.first else { return }
            
            DispatchQueue.main.async {
                self.address = [
                    placemark.thoroughfare,
                    placemark.subThoroughfare,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.country
                ].compactMap { $0 }.joined(separator: ", ")
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
                throw NSError(domain: "AddProject", code: 401, userInfo: [NSLocalizedDescriptionKey: "No hay token de autenticación"])
            }
            
            let url = URL(string: "https://api.friendlypayroll.net/api/projects/store-data-project")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Convertir el presupuesto a Double si es posible
            let budgetValue = Double(budget.replacingOccurrences(of: ",", with: ".")) ?? 0.0
            
            let projectData: [String: Any] = [
                "name": projectName,
                "latitude": String(coordinate.latitude),
                "longitude": String(coordinate.longitude),
                "address": address,
                "budget": budgetValue, // Nuevo campo de presupuesto
                "status": true
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
                        self.alertMessage = "Error al crear el proyecto: \(error.localizedDescription)"
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
                        self.alertMessage = "El proyecto ha sido creado correctamente."
                    } else {
                        if let data = data, let responseString = String(data: data, encoding: .utf8) {
                            self.alertTitle = "Error"
                            self.alertMessage = "Error al crear el proyecto: \(responseString)"
                        } else {
                            self.alertTitle = "Error"
                            self.alertMessage = "Error al crear el proyecto. Código: \(httpResponse.statusCode)"
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
                self.alertMessage = "Error al crear el proyecto: \(error.localizedDescription)"
                self.showAlert = true
            }
        }
    }
}

#Preview {
    AddProjectView(isPresented: .constant(true), onProjectAdded: {})
} 
