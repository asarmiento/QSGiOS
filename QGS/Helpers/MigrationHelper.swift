//
//  MigrationHelper.swift
//  QGS
//
//  Created by Edin Martinez on 9/4/25.
//

import Foundation

class MigrationHelper {
    static let shared = MigrationHelper()
    
    private let defaults = UserDefaults.standard
    private let keyMigrationCompleted = "keychain_migration_completed"
    
    private init() {}
    
    func runMigrationsIfNeeded() {
        // Verificar si ya se ejecutó esta migración
        if !defaults.bool(forKey: keyMigrationCompleted) {
            migrateTokenToKeychain()
            defaults.set(true, forKey: keyMigrationCompleted)
            defaults.synchronize()
        }
    }
    
    private func migrateTokenToKeychain() {
        if let token = defaults.string(forKey: "authToken"), !token.isEmpty {
            // Asegurarse de que el token está en UserDefaults y UserManager
            // El UserManager se encargará de intentar guardarlo en Keychain si está disponible
            if let userManagerToken = UserManager.shared.getAuthToken, userManagerToken != token {
                // Si los tokens no coinciden, actualizar UserDefaults con el token de UserManager
                defaults.set(userManagerToken, forKey: "authToken")
                defaults.synchronize()
                print("✅ Migración: Token de UserManager guardado en UserDefaults")
            } else {
                print("✅ Migración: Token ya está sincronizado entre UserDefaults y UserManager")
            }
        } else {
            // Si no hay token en UserDefaults pero sí en UserManager, guardarlo en UserDefaults
            if let userManagerToken = UserManager.shared.getAuthToken, !userManagerToken.isEmpty {
                defaults.set(userManagerToken, forKey: "authToken")
                defaults.synchronize()
                print("✅ Migración: Token restaurado desde UserManager a UserDefaults")
            } else {
                print("ℹ️ No hay token que migrar")
            }
        }
    }
} 