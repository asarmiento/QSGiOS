//
//  SplashScreen.swift
//  QGS
//
//  Created by Edin Martinez on 8/11/24.
//
import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    @State private var size = 0.5
    @State private var opacity = 0.5
    @State private var isUserValid = false
    @State private var isLoading = true

    var body: some View {
        if isActive {
            if isUserValid {
                MainTabView() // ✅ Redirige al TabView si el usuario está autenticado
            } else {
                Login() // ✅ Redirige a Login si no está autenticado
            }
        } else {
            VStack {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 200)
                    .scaleEffect(size)
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(.easeIn(duration: 1.2)) {
                            self.size = 1
                            self.opacity = 1.0
                        }
                    }
            }
            .onAppear {
                // ✅ Validar usuario y controlar la transición
                UserManager.shared.userExists { exists in
                    DispatchQueue.main.async {
                        self.isUserValid = exists
                        self.isLoading = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                self.isActive = true
                            }
                        }
                    }
                }
            }
        }
    }
 
        
}
