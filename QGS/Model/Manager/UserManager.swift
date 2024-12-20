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
    
    private var user: UserModel?
    private var context: ModelContext?
    
    private init() { }
    
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
    
    var authToken: String? {
        user?.token
    }
    
    var employeeId: String? {
        guard let id = user?.employeeId else { return nil }
        return String(id)
    }
    
    func refreshUser() {
        loadUser()
    }
    
    func saveUser(from response: LoginResponse) {
        guard let context = context else {
            logger.error("Error: ModelContext no está configurado.")
            return
        }
        
        do {
            let newUser = UserModel(
                name: response.user.name,
                email: response.user.email,
                token: response.token,
                employeeId: response.user.employee.id,
                sysconf: String(response.sysconf),
                type: response.user.type
            )
            
            // Eliminar usuarios previos
            let existingUsers = try context.fetch(FetchDescriptor<UserModel>())
            for existingUser in existingUsers {
                context.delete(existingUser)
            }
            
            context.insert(newUser)
            try context.save()
            user = newUser
            logger.info("Usuario guardado exitosamente")
        } catch {
            logger.error("Error al guardar el usuario: \(error.localizedDescription)")
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
                Endpoints.login,
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
