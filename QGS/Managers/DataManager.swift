//
//  DataManager.swift
//  QGS
//
//  Created by Anwar Sarmiento on 12/9/24.
//

import SwiftUI
import SwiftData

class DataManager {
    static let shared = DataManager()

    private init() {
        let currentSchemaVersion = 2
        let storedVersion = UserDefaults.standard.integer(forKey: "schemaVersion")
        
        if storedVersion < currentSchemaVersion {
            performMigration(from: storedVersion, to: currentSchemaVersion)
            UserDefaults.standard.set(currentSchemaVersion, forKey: "schemaVersion")
        }
    }

    private func performMigration(from oldVersion: Int, to newVersion: Int) {
        print("Migrando de versión \(oldVersion) a \(newVersion)")
        // Lógica de migración
    }
}
