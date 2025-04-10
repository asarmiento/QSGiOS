//
//  UserManager.swift
//  QGS
//
//  Created by Anwar Sarmiento on 12/8/24.
//

import Foundation
import SwiftData
import OSLog

class UserManager {
    static let shared = UserManager()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "QGS", category: "UserManager")
    
    @Published private(set) var loadingState: LoadingState = .idle
    
    // Propiedades para almacenar datos del usuario
    private var userId: String?
    private var userName: String?
    private var userEmail: String?
    private var authToken: String?
    private var employeeId: String?
    private var sysconfId: Int?
    private var userType: String?
    
    private var user: UserModel?
    private var context: ModelContext?
    
    private init() {
        // Cargar datos guardados de UserDefaults
        let defaults = UserDefaults.standard
        self.userId = defaults.string(forKey: "userId")
        self.userName = defaults.string(forKey: "userName")
        self.userEmail = defaults.string(forKey: "userEmail")
        self.authToken = defaults.string(forKey: "authToken")
        self.employeeId = defaults.string(forKey: "employeeId")
        self.sysconfId = defaults.integer(forKey: "sysconfId")
        self.userType = defaults.string(forKey: "userType")
        
        // Verificar integridad
        if let token = self.authToken, !token.isEmpty {
            print("Token cargado desde UserDefaults: \(token.prefix(10))...")
            
            // Intentar guardar en Keychain (si está disponible)
            do {
                if let keychainManager = try? getKeychainManager() {
                    try keychainManager.save(key: "authToken", string: token)
                    print("Token respaldado en Keychain")
                }
            } catch {
                print("Error al respaldar token en Keychain: \(error)")
            }
        } else {
            // Intentar restaurar desde Keychain si está disponible
            do {
                if let keychainManager = try? getKeychainManager(),
                   let tokenFromKeychain = try? keychainManager.readString(key: "authToken"),
                   !tokenFromKeychain.isEmpty {
                    self.authToken = tokenFromKeychain
                    
                    // Guardar de vuelta en UserDefaults para mantener sincronización
                    defaults.set(tokenFromKeychain, forKey: "authToken")
                    defaults.synchronize()
                    
                    print("Token restaurado desde Keychain: \(tokenFromKeychain.prefix(10))...")
                }
            } catch {
                print("Error al intentar restaurar token desde Keychain: \(error)")
            }
        }
    }
    
    // Método para obtener una instancia del KeychainManager de forma segura
    private func getKeychainManager() throws -> KeychainManager? {
        // Verificar si podemos acceder al KeychainManager
        if let keychainClass = NSClassFromString("QGS.KeychainManager") as? KeychainManager.Type {
            return keychainClass.shared
        }
        
        // Si la clase no está disponible, intentar con otro enfoque
        return KeychainManager.shared
    }
    
    // Getters públicos
    var getAuthToken: String? {
        return authToken
    }
    
    var getUserType: String? {
        return userType
    }
    
    var getEmployeeId: String? {
        return employeeId
    }
    
    func configure(with context: ModelContext) {
        self.context = context
        loadUser()
        print("UserManager configurado con el contexto correctamente.")
    }
    
    private func loadUser() {
        guard let context = context else {
            logger.error("Error: ModelContext no está configurado.")
            return
        }
        do {
            user = try context.fetch(FetchDescriptor<UserModel>()).first
        } catch {
            logger.error("Error al obtener el usuario: \(error.localizedDescription)")
        }
    }
    
    func getUser() -> UserModel? {
        return user
    }
    
    func userExists(completion: @escaping (Bool) -> Void) {
        guard let context = context else {
            logger.error("Error: ModelContext no está configurado.")
            completion(false)
            return
        }
        
        do {
            // Verifica si hay al menos un usuario en la base de datos
            let userExists = try context.fetch(FetchDescriptor<UserModel>()).first != nil
            completion(userExists)
        } catch {
            logger.error("Error al verificar la existencia del usuario: \(error.localizedDescription)")
            completion(false) // En caso de error, asumimos que el usuario no existe
        }
    }
    
    func refreshUser() {
        loadUser()
    }
    
    func saveUser(from response: LoginResponse) {
        guard let user = response.user else {
            logger.error("Error: No se encontraron datos de usuario en la respuesta")
            return
        }
        
        // Guardar datos del usuario
        self.userId = String(user.id)
        self.userName = user.name
        self.userEmail = user.email
        self.authToken = response.token ?? ""
        self.employeeId = String(user.employee.id)
        self.sysconfId = user.sysconf_id
        self.userType = user.type
        
        // Guardar token en Keychain (si está disponible)
        if let token = response.token, !token.isEmpty {
            do {
                if let keychainManager = try? getKeychainManager() {
                    try keychainManager.save(key: "authToken", string: token)
                    print("Token guardado en Keychain exitosamente")
                }
            } catch {
                logger.error("Error al guardar token en Keychain: \(error.localizedDescription)")
            }
        }
        
        // Guardar datos en UserDefaults (fuente principal)
        let defaults = UserDefaults.standard
        defaults.set(self.userId, forKey: "userId")
        defaults.set(self.userName, forKey: "userName")
        defaults.set(self.userEmail, forKey: "userEmail")
        defaults.set(self.authToken, forKey: "authToken")
        defaults.set(self.employeeId, forKey: "employeeId")
        defaults.set(self.sysconfId, forKey: "sysconfId")
        defaults.set(self.userType, forKey: "userType")
        defaults.synchronize()
        
        // Actualizar el modelo SwiftData si está disponible
        if let context = self.context {
            do {
                let newUser = UserModel(
                    name: user.name,
                    email: user.email,
                    token: self.authToken ?? "",
                    employeeId: user.employee.id,
                    sysconf: String(user.sysconf_id),
                    type: user.type
                )
                
                // Eliminar usuarios previos
                let existingUsers = try context.fetch(FetchDescriptor<UserModel>())
                for existingUser in existingUsers {
                    context.delete(existingUser)
                }
                
                context.insert(newUser)
                try context.save()
                self.user = newUser
                logger.info("Usuario guardado exitosamente en SwiftData")
            } catch {
                logger.error("Error al guardar el usuario en SwiftData: \(error.localizedDescription)")
            }
        }
    }
    
    func validateAndSaveUser(_ userData: [String: Any]) async throws {
        loadingState = .loading
        
        guard let email = userData["email"] as? String,
              isValidEmail(email) else {
            loadingState = .failure(NSLocalizedString("INVALID_EMAIL", comment: ""))
            throw ValidationError.invalidEmail
        }
        
        guard let password = userData["password"] as? String,
              isValidPassword(password) else {
            loadingState = .failure(NSLocalizedString("INVALID_PASSWORD", comment: ""))
            throw ValidationError.invalidPassword
        }
        
        do {
            let loginResponse: LoginResponse = try await NetworkManager.shared.request(
                EndPoints.login,
                method: "POST",
                params: userData
            )
            saveUser(from: loginResponse)
            loadingState = .success
        } catch {
            loadingState = .failure(error.localizedDescription)
            throw error
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        let passwordRegEx = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$"
        let passwordPred = NSPredicate(format:"SELF MATCHES %@", passwordRegEx)
        return passwordPred.evaluate(with: password)
    }
    
    // Agregar un método para limpiar los datos de sesión
    func logout() {
        // Limpiar datos de memoria
        self.userId = nil
        self.userName = nil
        self.userEmail = nil
        self.authToken = nil
        self.employeeId = nil
        self.sysconfId = nil
        self.userType = nil
        self.user = nil
        
        // Limpiar UserDefaults
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "userId")
        defaults.removeObject(forKey: "userName")
        defaults.removeObject(forKey: "userEmail")
        defaults.removeObject(forKey: "authToken")
        defaults.removeObject(forKey: "employeeId")
        defaults.removeObject(forKey: "sysconfId")
        defaults.removeObject(forKey: "userType")
        defaults.synchronize()
        
        // Limpiar Keychain si está disponible
        do {
            if let keychainManager = try? getKeychainManager() {
                try keychainManager.delete(key: "authToken")
                print("Token eliminado de Keychain")
            }
        } catch {
            logger.error("Error al eliminar token de Keychain: \(error.localizedDescription)")
        }
        
        // Limpiar SwiftData si está disponible
        if let context = self.context {
            do {
                let existingUsers = try context.fetch(FetchDescriptor<UserModel>())
                for existingUser in existingUsers {
                    context.delete(existingUser)
                }
                try context.save()
                logger.info("Datos de usuario eliminados de SwiftData")
            } catch {
                logger.error("Error al eliminar datos de usuario de SwiftData: \(error.localizedDescription)")
            }
        }
    }
    
    // Agregar función pública para ejecutar migraciones
    func runMigrations() {
        let defaults = UserDefaults.standard
        
        // Verificar si la migración a Keychain ya se ejecutó
        if !defaults.bool(forKey: "keychain_migration_attempted") {
            print("🔄 Ejecutando migración de tokens...")
            
            // Obtener token actual de UserDefaults
            if let token = defaults.string(forKey: "authToken"), !token.isEmpty {
                // Intentar respaldar en Keychain si es posible
                do {
                    if let keychainManager = try? getKeychainManager() {
                        try keychainManager.save(key: "authToken", string: token)
                        print("✅ Token migrado exitosamente a Keychain")
                    }
                } catch {
                    print("⚠️ No se pudo migrar el token a Keychain: \(error.localizedDescription)")
                }
            }
            
            // Marcar la migración como intentada
            defaults.set(true, forKey: "keychain_migration_attempted")
            defaults.synchronize()
        }
    }
}

enum ValidationError: LocalizedError {
    case invalidEmail
    case invalidPassword
    case invalidInput(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return NSLocalizedString("INVALID_EMAIL", comment: "")
        case .invalidPassword:
            return NSLocalizedString("INVALID_PASSWORD", comment: "")
        case .invalidInput(let field):
            return String(format: NSLocalizedString("INVALID_FIELD", comment: ""), field)
        }
    }
}
