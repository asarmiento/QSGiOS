import SwiftUI
import MapKit

struct BoxGPS: View {
    @StateObject var locationManager = LocationViewController.shared
    @StateObject var recordManager = RecordManager()
    
    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                // Mapa
                MapView(coordinate: CLLocationCoordinate2D(
                    latitude: Double(locationManager.latitude) ?? 0.0,
                    longitude: Double(locationManager.longitude) ?? 0.0
                ))
                .frame(height: 200)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                // Coordenadas
                HStack {
                    Group {
                        Label {
                            VStack {
                                Text("LATITUDE")
                                    .font(.system(size: 20, weight: .bold))
                                    .padding(5)
                                Text(locationManager.latitude.isEmpty ? "0.0" : locationManager.latitude)
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))
                                    .padding(5)
                            }
                        } icon: {}

                        Label {
                            VStack {
                                Text("LONGITUDE")
                                    .font(.system(size: 20, weight: .bold))
                                    .padding(5)
                                Text(locationManager.longitude.isEmpty ? "0.0" : locationManager.longitude)
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))
                                    .padding(5)
                            }
                        } icon: {}
                    }
                    .frame(width: 150, height: 80)
                    .border(Color.black, width: 1)
                }
            }
            .padding()
            
            if recordManager.isLoading {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    )
            }
        }
        .disabled(recordManager.isLoading)
        .alert(isPresented: Binding(
            get: { recordManager.error != nil },
            set: { if !$0 { recordManager.error = nil } }
        )) {
            Alert(
                title: Text("Error"),
                message: Text(recordManager.error?.localizedDescription ?? "Error desconocido"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// Vista del mapa estático
struct MapView: View {
    let coordinate: CLLocationCoordinate2D
    
    var body: some View {
        Map(coordinateRegion: .constant(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )), interactionModes: [], // Deshabilita todas las interacciones
            annotationItems: [MapLocation(coordinate: coordinate)]) { location in
            MapMarker(coordinate: location.coordinate, tint: .blue)
        }
    }
}

// Modelo para la ubicación en el mapa
struct MapLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    BoxGPS()
} 