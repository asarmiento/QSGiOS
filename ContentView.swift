import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var showingErrorAlert = false
    
    var body: some View {
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