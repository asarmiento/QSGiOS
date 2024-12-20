// En la parte superior del archivo
private func checkLocationAuthorization() {
    if !locationManager.isAuthorized {
        // Solo mostrar la alerta si los permisos están denegados
        if CLLocationManager.authorizationStatus() == .denied {
            showLocationAlert = true
        } else {
            locationManager.requestLocationPermission()
        }
    }
}

// Actualizar la alerta
.alert(isPresented: $showLocationAlert) {
    Alert(
        title: Text("Permiso de Localización"),
        message: Text("La aplicación necesita acceso a tu ubicación para registrar tu entrada/salida. Por favor, otorga los permisos en Configuración."),
        primaryButton: .default(Text("Abrir Configuración")) {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        },
        secondaryButton: .cancel(Text("Cancelar"))
    )
} 