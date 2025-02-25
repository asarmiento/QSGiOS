import SwiftUI

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    
    var body: some View {
        VStack {
            TextField("Usuario", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            SecureField("Contraseña", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Iniciar Sesión") {
                login()
            }
            .padding()
        }
        .padding()
    }
    
    private func login() {
        // Aquí iría la lógica para autenticar al usuario
        // Si la autenticación es exitosa:
        UserDefaults.standard.set("token_de_autenticacion", forKey: "authToken")
        // Redirigir a la vista principal
    }
} 