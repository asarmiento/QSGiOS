import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var showingUpdateAlert = false
    @State private var versionInfo: (current: String, latest: String, needsUpdate: Bool)?
    @State private var checkingVersion = false
    @State private var versionError: String?
    
    var body: some View {
        ZStack {
            // Contenido existente
            VStack {
                switch locationManager.locationStatus {
                case .authorizedWhenInUse, .authorizedAlways:
                    if let location = locationManager.lastLocation {
                        LocationInfoView(location: location)
                    } else {
                        LoadingView()
                    }
                case .denied, .restricted:
                    LocationPermissionDeniedView()
                case .notDetermined:
                    RequestLocationButton(locationManager: locationManager)
                default:
                    EmptyView()
                }
                
                if let errorMessage = locationManager.errorMessage {
                    ErrorBannerView(message: errorMessage)
                }
            }
            .padding()
            
            // Alerta de actualización
            if showingUpdateAlert,
               let versionInfo = versionInfo {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        UpdateAlertView(
                            currentVersion: versionInfo.current,
                            latestVersion: versionInfo.latest,
                            isPresented: $showingUpdateAlert
                        )
                        .padding()
                    )
            }
        }
        .task {
            await checkVersion()
        }
        .alert("Error", isPresented: .constant(versionError != nil)) {
            Button("OK") {
                versionError = nil
            }
        } message: {
            if let error = versionError {
                Text(error)
            }
        }
    }
    
    private func checkVersion() async {
        guard !checkingVersion else { return }
        checkingVersion = true
        
        do {
            let result = try await VersionCheckService.shared.checkForUpdate()
            DispatchQueue.main.async {
                versionInfo = result
                showingUpdateAlert = result.needsUpdate
                checkingVersion = false
            }
        } catch {
            DispatchQueue.main.async {
                versionError = error.localizedDescription
                checkingVersion = false
            }
        }
    }
}

// Vistas auxiliares para mejor organización
struct LocationInfoView: View {
    let location: CLLocation
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Ubicación actual:")
                .font(TextStyles.heading)
            Text("Lat: \(location.coordinate.latitude, specifier: "%.6f")")
                .font(TextStyles.bodyText)
            Text("Lon: \(location.coordinate.longitude, specifier: "%.6f")")
                .font(TextStyles.bodyText)
        }
    }
}

struct LocationPermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Se requieren permisos de ubicación")
                .font(TextStyles.heading)
            Text("Por favor, habilita los permisos de ubicación en la configuración")
                .font(TextStyles.bodyText)
                .multilineTextAlignment(.center)
            Button("Abrir Ajustes") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}

struct RequestLocationButton: View {
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        Button(action: {
            locationManager.requestLocationPermission()
        }) {
            if locationManager.isRequestingAuthorization {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Text("Permitir acceso a ubicación")
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(locationManager.isRequestingAuthorization)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Obteniendo ubicación...")
                .font(TextStyles.bodyText)
        }
    }
}

struct ErrorBannerView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(TextStyles.bodyText)
            .foregroundColor(.white)
            .padding()
            .background(Color.red.opacity(0.8))
            .cornerRadius(8)
            .padding(.horizontal)
            .transition(.move(edge: .top))
            .animation(.easeInOut, value: message)
    }
} 