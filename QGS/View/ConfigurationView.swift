import SwiftUI

struct ConfigurationView: View {
    // Constantes para el grid
    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 15), count: 3)
    private let spacing: CGFloat = 15
    
    // Estructura para los items del menú
    private struct MenuItem: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let destination: AnyView?
        
        init(icon: String, title: String, destination: AnyView? = nil) {
            self.icon = icon
            self.title = title
            self.destination = destination
        }
    }
    
    // Lista de menú items
    private var menuItems: [MenuItem] {
        [
            
            MenuItem(icon: "Employees", title: "Empleados", destination: AnyView(EmployeeListView())),
            MenuItem(icon: "Message1", title: "Reportes", destination: AnyView(TimeRecordsView())),
            MenuItem(icon: "Message2", title: "Calendario", destination: nil),
            MenuItem(icon: "Message3", title: "Mensaje", destination: AnyView(EmployeeMessagingView())),
            MenuItem(icon: "NewProject", title: "Nuevo Proyecto", destination: AnyView(ProjectListView())),
            MenuItem(icon: "NewProject2", title: "Compras Proyectos", destination: nil),
            MenuItem(icon: "Projects", title: "Proyectos", destination: AnyView(ProjectsListView())),
            MenuItem(icon: "Projects2", title: "Ubicación de Empleados", destination: AnyView(EmployeeMapView())),
            MenuItem(icon: "WorkHours", title: "Horas Trabajo", destination: AnyView(PDFViewContainer()))
        ]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
#if QGS_TARGET
                // Marca de agua
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .opacity(0.1) // Ajusta la opacidad según necesites
#elseif FRIENDLY_TARGET
                
                // Marca de agua
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .opacity(0.1) // Ajusta la opacidad según necesites
                #elseif MCS_TARGET
                
                // Marca de agua
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .opacity(0.1) // Ajusta la opacidad según necesites
                
                #endif
                ScrollView {
                    VStack(spacing: 20) {
                                // Grid de iconos
                                LazyVGrid(columns: columns, spacing: spacing) {
                                    ForEach(menuItems) { item in
                                        MenuButton(
                                            icon: item.icon,
                                            title: item.title,
                                            destination: item.destination
                                        )
                                    }
                                }
                                .padding()
                    
                    }
                }
            }
            .navigationTitle("Configuración")
        }
    }
    
    private var getUser: UserModel? {
        return UserManager.shared.getUser()
    }
}

// Vista del botón del menú
struct MenuButton: View {
    let icon: String
    let title: String
    let destination: AnyView?
    
    var body: some View {
        if let destination = destination {
            NavigationLink(destination: destination) {
                MenuButtonContent(icon: icon, title: title)
            }
        } else {
            Button(action: {}) {
                MenuButtonContent(icon: icon, title: title)
            }
        }
    }
}

// Extraemos el contenido del botón a una vista separada
struct MenuButtonContent: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(radius: 2)
        )
    }
}

// Vista para cuando no hay acceso
struct NoAccessView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No tiene permisos para acceder a esta sección.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

// Preview
#Preview {
    ConfigurationView()
}
