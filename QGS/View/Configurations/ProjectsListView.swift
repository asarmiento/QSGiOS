import SwiftUI

struct ProjectsListView: View {
    @StateObject private var viewModel = ProjectsViewModel()
    @State private var showingAddProject = false

    var body: some View {
        ZStack {
            // Marca de agua
            Image("QGS-Branding-01")
                .resizable()
                .scaledToFit()
                .opacity(0.1)

            VStack {
                if viewModel.isLoading {
                    ProgressView(NSLocalizedString("Cargando proyectos...", comment: ""))
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error)
                } else {
                    List(viewModel.projects) { project in
                        ProjectRow(project: project)
                    }
                    .refreshable {
                        viewModel.fetchProjects()
                    }
                }
            }
        }
        .navigationTitle(NSLocalizedString("Proyectos", comment: ""))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let user = UserManager.shared.getUser(), user.type != "employee" {
                    Button(action: {
                        showingAddProject = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color.myPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddProject) {
            AddProjectView(isPresented: $showingAddProject, onProjectAdded: {
                viewModel.fetchProjects()
            })
        }
        .onAppear {
            viewModel.fetchProjects()
        }
    }
}

struct ProjectRow: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(project.name)
                .font(.headline)

            HStack(alignment: .top) {
                Text(project.address)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Botón para abrir el mapa
                Button(action: {
                    openMap()
                }) {
                    Image(systemName: "location.fill")
                        .foregroundColor(Color.myPrimary)
                        .font(.system(size: 20))
                }
            }

            Divider()
            
            if let user = getUser {
                if user.type != "employee" {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(NSLocalizedString("Horas Quincenales", comment: ""))
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(project.hours ?? "0.00")
                                .font(.caption2)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text(NSLocalizedString("Horas Mensuales", comment: ""))
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(project.month ?? "0.00")
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var getUser: UserModel? {
        return UserManager.shared.getUser()
    }
    
    private func openMap() {
        if let latitude = Double(project.altitude),
           let longitude = Double(project.longitude) {
            let coordinates = "\(latitude),\(longitude)"
            let addressEncoded = project.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            
            // Primero intentamos abrir en Apple Maps
            let appleMapsURL = "maps://?q=\(addressEncoded)&ll=\(coordinates)"
            if let url = URL(string: appleMapsURL), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
            // Si no se puede abrir Apple Maps, intentamos con Google Maps
            else {
                let googleMapsURL = "comgooglemaps://?q=\(coordinates)&center=\(coordinates)"
                if let url = URL(string: googleMapsURL), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
                // Si ninguno está disponible, abrimos en el navegador
                else {
                    let webURL = "https://www.google.com/maps/search/?api=1&query=\(coordinates)"
                    if let url = URL(string: webURL) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }
}

struct ErrorView: View {
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

