//
//  UserManager.swift
//  QGS
//
//  Created by Anwar Sarmiento on 12/8/24.
//

import Foundation
import SwiftData

class UserManager {
    static let shared = UserManager()
    private var user: UserModel?
    private var context: ModelContext?
    
    private init() { }
    
    func configure(with context: ModelContext) {
        self.context = context
        loadUser()
       // performMigration(context: modelContainer.mainContext)

        print("UserManager configurado con el contexto correctamente.")
    }
    
    private func loadUser() {
        guard let context = context else {
            print("Error: ModelContext no está configurado.")
            return
        }
        do {
            user = try context.fetch(FetchDescriptor<UserModel>()).first
        } catch {
            print("Error al obtener el usuario: \(error)")
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
            print("Error: ModelContext no está configurado.")
            return
        }
        print("guardando usuario \(response)")
        do {
            // Crear un nuevo modelo UserModel desde el JSON
            let newUser = UserModel(
                name: response.user.name,
                email: response.user.email,
                token: response.token,
                employeeId: response.user.employee.id,
                sysconf: response.sysconf,
                type: response.user.type
                
            )
            
            // Eliminar usuarios previos (opcional)
            let existingUsers = try context.fetch(FetchDescriptor<UserModel>())
            for existingUser in existingUsers {
                context.delete(existingUser)
            }
            
            // Guardar el nuevo usuario
            try context.insert(newUser)
            try context.save()
            user = newUser
        } catch {
            print("Error al guardar el usuario: \(error)")
        }
    }
    
    func performMigration(context: ModelContext) {
        do {
            // Busca los registros antiguos
            let fetchDescriptor = FetchDescriptor<UserModel>()
            let oldRecords = try context.fetch(fetchDescriptor)

            // Migra cada registro al nuevo modelo
            for record in oldRecords {
                if record.type == nil {
                    record.type = "employee"
                }
            }

            // Guarda los cambios
            try context.save()
            print("Migración completada exitosamente.")
        } catch {
            print("Error al realizar la migración: \(error.localizedDescription)")
        }
    }

}
