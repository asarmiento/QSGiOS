import SwiftUI
import MapKit

// ViewModel para la vista de lista de proyectos
@preconcurrency
@MainActor
class ProjectListViewModel: NSObject, ObservableObject, URLSessionTaskDelegate, URLSessionDataDelegate {
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var searchText = ""
    
    private var urlSession: URLSession!
    private var activeDataTasks: Set<URLSessionDataTask> = []
    
    var filteredProjects: [Project] {
        if searchText.isEmpty {
            return projects
        } else {
            return projects.filter { project in
                project.name.localizedCaseInsensitiveContains(searchText) ||
                project.address.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
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
    
    func loadProjects() async {
        isLoading = true
        projects = []
        
        do {
            guard let token = UserManager.shared.authToken else {
                throw NSError(domain: "ProjectList", code: 401, userInfo: [NSLocalizedDescriptionKey: "No hay token de autenticación"])
            }
            
            let url = URL(string: "https://api.friendlypayroll.net/api/projects/list-data-project")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            // Crear una tarea y guardarla en activeDataTasks
            let dataTask = urlSession.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }
                
                Task { @MainActor in
                    self.isLoading = false
                    
                    if let error = error {
                        self.alertTitle = "Error"
                        self.alertMessage = "Error al cargar los proyectos: \(error.localizedDescription)"
                        self.showAlert = true
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        self.alertTitle = "Error"
                        self.alertMessage = "Error: Respuesta del servidor inválida"
                        self.showAlert = true
                        return
                    }
                    
                    if httpResponse.statusCode == 200 {
                        if let data = data {
                            do {
                                let decoder = JSONDecoder()
                                let projectsResponse = try decoder.decode([Project].self, from: data)
                                self.projects = projectsResponse
                            } catch {
                                // Si falla la decodificación directa, intentar procesar manualmente
                                if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                                    var newProjects: [Project] = []
                                    
                                    for projectData in json {
                                        let id = projectData["id"] as? Int ?? 0
                                        let name = projectData["name"] as? String ?? ""
                                        let address = projectData["address"] as? String ?? ""
                                        let altitude = projectData["altitude"] as? String ?? ""
                                        let longitude = projectData["longitude"] as? String ?? ""
                                        let status = projectData["status"] as? Int ?? 0
                                        
                                        // Manejar el budget que puede ser String o Double
                                        var budget: Double = 0.0
                                        if let budgetDouble = projectData["budget"] as? Double {
                                            budget = budgetDouble
                                        } else if let budgetString = projectData["budget"] as? String,
                                                  let budgetValue = Double(budgetString) {
                                            budget = budgetValue
                                        }
                                        
                                        let createdAt = projectData["created_at"] as? String
                                        let updatedAt = projectData["updated_at"] as? String
                                        let hours = projectData["hours"] as? String
                                        let month = projectData["month"] as? String
                                        let year = projectData["year"] as? String
                                        let sysconfId = projectData["sysconf_id"] as? Int
                                        
                                        let project = Project(
                                            id: id,
                                            name: name,
                                            address: address,
                                            altitude: altitude,
                                            longitude: longitude,
                                            status: status,
                                            budget: budget,
                                            createdAt: createdAt,
                                            updatedAt: updatedAt,
                                            hours: hours,
                                            month: month,
                                            year: year,
                                            sysconfId: sysconfId
                                        )
                                        
                                        newProjects.append(project)
                                    }
                                    
                                    self.projects = newProjects
                                } else {
                                    self.alertTitle = "Error"
                                    self.alertMessage = "Error al decodificar los proyectos: \(error.localizedDescription)"
                                    self.showAlert = true
                                }
                            }
                        }
                    } else {
                        if let data = data, let responseString = String(data: data, encoding: .utf8) {
                            self.alertTitle = "Error"
                            self.alertMessage = "Error al cargar los proyectos: \(responseString)"
                        } else {
                            self.alertTitle = "Error"
                            self.alertMessage = "Error al cargar los proyectos. Código: \(httpResponse.statusCode)"
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
                self.alertMessage = "Error al cargar los proyectos: \(error.localizedDescription)"
                self.showAlert = true
            }
        }
    }
}

struct ProjectListView: View {
    @StateObject private var viewModel = ProjectsViewModel() // Usar el ProjectsViewModel existente
    @State private var hasAccess: Bool = false
    @State private var showingAddProject = false
    @State private var showingEditProject = false
    @State private var selectedProjectId: Int = 0
    @State private var showingMapView = false
    @State private var searchText = ""
    
    // Filtrar proyectos basados en el texto de búsqueda
    var filteredProjects: [Project] {
        if searchText.isEmpty {
            return viewModel.projects
        } else {
            return viewModel.projects.filter { project in
                project.name.localizedCaseInsensitiveContains(searchText) ||
                project.address.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if hasAccess {
                    VStack(spacing: 0) {
                        // Barra de navegación superior personalizada
                        HStack {
                            Button(action: {
                                showingMapView = true
                            }) {
                                HStack {
                                    Image(systemName: "map")
                                    Text("Ver Mapa")
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showingAddProject = true
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Nuevo Proyecto")
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                        
                        // Barra de búsqueda
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Buscar proyectos", text: $searchText)
                                .padding(.vertical, 8)
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        // Título de sección
                        HStack {
                            Text("Administración de Proyectos")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top, 8)
                            Spacer()
                        }
                        
                        if filteredProjects.isEmpty && !viewModel.isLoading {
                            VStack(spacing: 20) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                
                                Text("No se encontraron proyectos")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                
                                Button(action: {
                                    viewModel.fetchProjects()
                                }) {
                                    Text("Recargar")
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            List {
                                ForEach(filteredProjects) { project in
                                    ProjectRowWithEditButton(
                                        project: project,
                                        onEditTapped: {
                                            selectedProjectId = project.id
                                            showingEditProject = true
                                        }
                                    )
                                    .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                                }
                            }
                            .listStyle(InsetGroupedListStyle())
                            .refreshable {
                                viewModel.fetchProjects()
                            }
                        }
                    }
                    
                    if viewModel.isLoading {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                        
                        ProgressView("Cargando proyectos...")
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                } else {
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
                        .padding()
                    }
                }
            }
            .navigationTitle("Proyectos")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage ?? "Ha ocurrido un error desconocido"),
                    dismissButton: .default(Text("Aceptar"))
                )
            }
            .sheet(isPresented: $showingAddProject) {
                AddProjectView(isPresented: $showingAddProject, onProjectAdded: {
                    viewModel.fetchProjects()
                })
            }
            .sheet(isPresented: $showingEditProject) {
                EditProjectView(isPresented: $showingEditProject, projectId: selectedProjectId, onProjectUpdated: {
                    viewModel.fetchProjects()
                })
            }
            .sheet(isPresented: $showingMapView) {
                ProjectsMapView(projects: viewModel.projects)
            }
            .onAppear {
                // Verificar si el usuario tiene acceso
                checkUserAccess()
                
                if hasAccess {
                    // Cargar los proyectos
                    viewModel.fetchProjects()
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

// Componente de fila de proyecto con botón de edición
struct ProjectRowWithEditButton: View {
    let project: Project
    let onEditTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Información del proyecto
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(project.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    // Indicador de estado
                    HStack(spacing: 4) {
                        Circle()
                            .fill(project.status != 0 ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        
                        Text(project.status != 0 ? "Activo" : "Inactivo")
                            .font(.caption)
                            .foregroundColor(project.status != 0 ? .green : .red)
                    }
                }
                
                Text(project.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text("Presupuesto:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("$\(String(format: "%.2f", project.budget))")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            
            // Botón de edición (ocupa todo el ancho)
            Button(action: onEditTapped) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Editar Proyecto")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// Extensión para manejar la alerta en ProjectsViewModel
extension ProjectsViewModel {
    var showAlert: Bool {
        get { return errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }
}

// Vista del mapa para mostrar todos los proyectos
struct ProjectsMapView: View {
    let projects: [Project]
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.472337, longitude: -84.406377), // Ciudad de cincinnati
        span: MKCoordinateSpan(latitudeDelta: 0.9, longitudeDelta: 0.9)
    )
    @State private var selectedProject: Project?
    @State private var showingEditProject = false
    @State private var mapType: MKMapType = .standard
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            // Dividir la vista en componentes más pequeños
            MapContentView(
                region: $region,
                validProjects: validProjects,
                selectedProject: $selectedProject,
                showingEditProject: $showingEditProject,
                mapType: $mapType,
                centerMapOnProjects: centerMapOnProjects,
                dismiss: dismiss
            )
            .navigationTitle("Ubicación de Proyectos")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingEditProject) {
                if let project = selectedProject {
                    EditProjectView(
                        isPresented: $showingEditProject,
                        projectId: project.id,
                        onProjectUpdated: {
                            // Aquí podríamos recargar los datos si fuera necesario
                        }
                    )
                }
            }
        }
        .onDisappear {
            // Limpiar recursos al desaparecer la vista
            selectedProject = nil
        }
    }
    
    // Filtrar proyectos con coordenadas válidas
    var validProjects: [Project] {
        projects.filter { project in
            let lat = Double(project.altitude) ?? 0
            let lon = Double(project.longitude) ?? 0
            return lat != 0 && lon != 0
        }
    }
    
    // Centrar el mapa en los proyectos
    func centerMapOnProjects() {
        guard !validProjects.isEmpty else { return }
        
        // Si solo hay un proyecto, centrar en él
        if validProjects.count == 1, let project = validProjects.first {
            region.center = project.coordinate
            region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            return
        }
        
        // Si hay múltiples proyectos, calcular el centro y el span
        var minLat: Double = 90.0
        var maxLat: Double = -90.0
        var minLon: Double = 180.0
        var maxLon: Double = -180.0
        
        for project in validProjects {
            let lat = project.coordinate.latitude
            let lon = project.coordinate.longitude
            
            minLat = min(minLat, lat)
            maxLat = max(maxLat, lat)
            minLon = min(minLon, lon)
            maxLon = max(maxLon, lon)
        }
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        // Añadir un poco de margen
        let latDelta = (maxLat - minLat) * 1.5
        let lonDelta = (maxLon - minLon) * 1.5
        
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: max(latDelta, 0.01), longitudeDelta: max(lonDelta, 0.01))
        )
    }
}

// Vista de contenido del mapa (separada para simplificar)
struct MapContentView: View {
    @Binding var region: MKCoordinateRegion
    let validProjects: [Project]
    @Binding var selectedProject: Project?
    @Binding var showingEditProject: Bool
    @Binding var mapType: MKMapType
    @State private var mapTypeChanged = false
    let centerMapOnProjects: () -> Void
    let dismiss: DismissAction
    
    var body: some View {
        ZStack {
            // Mapa base
            mapView
            
            // Etiquetas de proyectos
            projectLabels
            
            // Controles y tarjeta de información
            controlsAndInfoCard
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Text("Cerrar")
                        .font(.system(size: 16))
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    centerMapOnProjects()
                }) {
                    Image(systemName: "location")
                }
            }
        }
        .onAppear {
            // Retrasar ligeramente el centrado para permitir que el mapa se cargue primero
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                centerMapOnProjects()
            }
        }
    }
    
    // Mapa base
    private var mapView: some View {
        #if swift(>=5.9) && canImport(MapKit) && os(iOS)
        if #available(iOS 17.0, *) {
            return Map {
                ForEach(validProjects) { project in
                    if let latitude = Double(project.altitude), 
                       let longitude = Double(project.longitude) {
                        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        Marker(project.name, coordinate: coordinate)
                            .tint(project.status == 1 ? .green : .red)
                    }
                }
            }
            .mapStyle(mapType == .standard ? .standard : .hybrid)
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .edgesIgnoringSafeArea(.all)
        } else {
            return Map(coordinateRegion: $region,
                interactionModes: .all,
                showsUserLocation: true,
                userTrackingMode: .none,
                annotationItems: validProjects) { project in
                MapMarker(coordinate: CLLocationCoordinate2D(
                    latitude: Double(project.altitude) ?? 0.0,
                    longitude: Double(project.longitude) ?? 0.0
                ), tint: project.status == 1 ? .green : .red)
            }
            .edgesIgnoringSafeArea(.all)
        }
        #else
        return Map(coordinateRegion: $region,
            interactionModes: .all,
            showsUserLocation: true,
            userTrackingMode: .none,
            annotationItems: validProjects) { project in
            MapMarker(coordinate: CLLocationCoordinate2D(
                latitude: Double(project.altitude) ?? 0.0,
                longitude: Double(project.longitude) ?? 0.0
            ), tint: project.status == 1 ? .green : .red)
        }
        .edgesIgnoringSafeArea(.all)
        #endif
    }
    
    // Etiquetas de proyectos
    private var projectLabels: some View {
        ZStack {
            ForEach(validProjects) { project in
                projectLabel(for: project)
            }
        }
        .allowsHitTesting(true)
    }
    
    // Etiqueta individual para un proyecto
    private func projectLabel(for project: Project) -> some View {
        // Obtener la posición válida (si existe)
        let validPosition = getValidPosition(for: project)
        
        // Crear una vista condicional
        return ZStack {
            // Solo mostrar el contenido si las coordenadas son válidas
            if validPosition != nil {
                // Fondo de la etiqueta
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.white.opacity(0.8))
                    .shadow(radius: 1)
                    .frame(width: CGFloat(project.name.count) * 7 + 10, height: 24)
                
                // Texto de la etiqueta con fuente del sistema específica (no variable)
                Text(project.name)
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(.black)
            }
        }
        .position(
            x: validPosition?.x ?? 0,
            y: (validPosition?.y ?? 0) + 180
        )
        .opacity(validPosition != nil ? 1 : 0) // Ocultar si no hay posición válida
        .onTapGesture {
            if validPosition != nil {
                selectedProject = project
            }
        }
    }
    
    // Función auxiliar para obtener una posición válida
    private func getValidPosition(for project: Project) -> CGPoint? {
        let xOffset = region.getOffsetX(for: project.coordinate)
        let yOffset = region.getOffsetY(for: project.coordinate)
        
        // Verificar si las coordenadas son válidas
        guard !xOffset.isNaN && !yOffset.isNaN && 
              xOffset.isFinite && yOffset.isFinite else {
            return nil
        }
        
        return CGPoint(x: xOffset, y: yOffset)
    }
    
    // Controles y tarjeta de información
    private var controlsAndInfoCard: some View {
        VStack {
            // Selector de tipo de mapa
            mapTypeSelector
            
            Spacer()
            
            // Tarjeta de información del proyecto seleccionado
            if let project = selectedProject {
                projectInfoCard(project)
            }
        }
    }
    
    // Selector de tipo de mapa
    private var mapTypeSelector: some View {
        let picker = Picker("Tipo de Mapa", selection: $mapType) {
            Text("Estándar").tag(MKMapType.standard)
            Text("Satélite").tag(MKMapType.satellite)
            Text("Híbrido").tag(MKMapType.hybrid)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(8)
        .background(Color.white.opacity(0.8))
        .cornerRadius(8)
        
        // Aplicar el onChange según la versión de iOS
        #if swift(>=5.9) && canImport(SwiftUI) && os(iOS)
        if #available(iOS 17.0, *) {
            return picker.onChange(of: mapType) { _, _ in
                // Forzar recarga del mapa cuando cambia el tipo
                withAnimation {
                    mapTypeChanged.toggle()
                }
            }
        } else {
            return picker.onChange(of: mapType) { newValue in
                // Forzar recarga del mapa cuando cambia el tipo
                withAnimation {
                    mapTypeChanged.toggle()
                }
            }
        }
        #else
        return picker.onChange(of: mapType) { newValue in
            // Forzar recarga del mapa cuando cambia el tipo
            withAnimation {
                mapTypeChanged.toggle()
            }
        }
        #endif
    }
    
    // Tarjeta de información del proyecto
    private func projectInfoCard(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Encabezado con nombre y estado
            HStack {
                Text(project.name)
                    .font(.system(size: 16, weight: .medium, design: .default))
                
                Spacer()
                
                // Indicador de estado
                HStack(spacing: 4) {
                    Circle()
                        .fill(project.status != 0 ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    
                    Text(project.status != 0 ? "Activo" : "Inactivo")
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundColor(project.status != 0 ? .green : .red)
                }
            }
            
            // Dirección
            Text(project.address)
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundColor(.secondary)
            
            // Presupuesto
            HStack {
                Text("Presupuesto:")
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(.secondary)
                
                Text("$\(String(format: "%.2f", project.budget))")
                    .font(.system(size: 12, weight: .medium, design: .default))
            }
            
            // Botones de acción
            Button(action: {
                showingEditProject = true
            }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Editar Proyecto")
                        .font(.system(size: 14, weight: .medium, design: .default))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            Button(action: {
                selectedProject = nil
            }) {
                HStack {
                    Image(systemName: "xmark")
                    Text("Cerrar")
                        .font(.system(size: 14, weight: .medium, design: .default))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding()
    }
}

// Extensión para obtener coordenadas de un proyecto
extension Project {
    var coordinate: CLLocationCoordinate2D {
        let lat = Double(altitude) ?? 0
        let lon = Double(longitude) ?? 0
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

// Extensión para calcular posiciones en el mapa
extension MKCoordinateRegion {
    func getOffsetX(for coordinate: CLLocationCoordinate2D) -> CGFloat {
        let spanX = span.longitudeDelta
        let centerX = center.longitude
        
        // Protección contra división por cero
        guard spanX > 0 else { return 0 }
        
        let offsetRatio = (coordinate.longitude - (centerX - spanX/2)) / spanX
        
        // Limitar el valor dentro de un rango válido
        let clampedRatio = max(0, min(1, offsetRatio))
        
        return CGFloat(clampedRatio) * (UIScreen.main.bounds.width - 20) + 10
    }
    
    func getOffsetY(for coordinate: CLLocationCoordinate2D) -> CGFloat {
        let spanY = span.latitudeDelta
        let centerY = center.latitude
        
        // Protección contra división por cero
        guard spanY > 0 else { return 0 }
        
        let offsetRatio = 1 - (coordinate.latitude - (centerY - spanY/2)) / spanY
        
        // Limitar el valor dentro de un rango válido
        let clampedRatio = max(0, min(1, offsetRatio))
        
        return CGFloat(clampedRatio) * (UIScreen.main.bounds.height - 20) + 10
    }
}

#Preview {
    ProjectListView()
} 
