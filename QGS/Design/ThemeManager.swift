//
//  ThemeManager.swift
//  QGS
//
//  Created by Edin Martinez on 8/11/25.
//

import SwiftUI

enum Theme {
    static let primary = Color.myPrimary  // usa tu Colors.swift
    // agrega más tokens si usas tipografías, espaciados, etc.
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: ThemeProtocol
    
    private init() {
        // Determine theme based on build target
        #if FRIENDLY_TARGET
        self.currentTheme = FriendlyTheme()
        #elseif MCS_TARGET
        self.currentTheme = MCSTheme()
        #else
        self.currentTheme = QGSTheme()
        #endif
    }
    
    // Allow runtime theme switching for testing
    func switchTheme(to theme: ThemeProtocol) {
        currentTheme = theme
    }

    func applyGlobalAppearance() {
        // Configura apariencias globales si las usas (UINavigationBar, UITabBar, etc.)
        // UINavigationBar.appearance().tintColor = UIColor(Theme.primary)
    }
}
