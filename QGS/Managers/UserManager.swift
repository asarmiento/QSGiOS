import Foundation
import SwiftData

class UserManager {
    static let shared = UserManager()
    
    var authToken: String? {
        // Aquí deberías obtener el token guardado (por ejemplo, de UserDefaults)
        return UserDefaults.standard.string(forKey: "authToken")
    }
    
    func isAuthenticated() -> Bool {
        // Verifica si el token es válido
        return authToken != nil
    }
    
    /// Verifica si el usuario existe (simulado) de forma asíncrona
    func userExists(completion: @escaping (Bool) -> Void) {
        // Refrescamos la info del usuario antes de verificar:
        refreshUser()
        
        // Simulación de asíncrono. Si no necesitas simular, omite el DispatchQueue.
        DispatchQueue.global().async {
            // Lógica real: si user != nil, userExists = true
            let userExists = (self.user != nil)
            
            // Llamamos al completion con el resultado
            completion(userExists)
        }
    }
    
    func logout() {
        // Elimina el token y cualquier información de sesión
        UserDefaults.standard.removeObject(forKey: "authToken")
    }
} 