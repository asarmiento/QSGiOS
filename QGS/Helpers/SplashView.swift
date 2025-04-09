//
//  SplashScreen.swift
//  QGS
//
//  Created by Anwar Sarmiento on 8/11/24.
//

import SwiftUI
import SwiftData

struct SplashView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isActive = false
    @State private var size = 0.1 // Comenzamos con un tamaño más pequeño
    @State private var opacity = 0.0 // Comenzamos completamente transparente
    @State private var y = 50.0 // Para el efecto de movimiento vertical
    
    let accessToken = UserManager.shared.getAuthToken
    let datecreatAt = UserDefaults.standard.string(forKey: "createdAt")
 //  let persistenceController = PersistenceController.shared
    
    var body: some View {
        
        if isActive {
            if currentUser != nil {
                MainTabView()
                    .navigationBarBackButtonHidden(false)
                    .onAppear {
                        UserManager.shared.configure(with: modelContext)
                        RecordManager.shared.configure(with: modelContext)
                    }
            } else {
                Login()
                    .onAppear {
                        UserManager.shared.configure(with: modelContext)
                        RecordManager.shared.configure(with: modelContext)
                    }
            }
        } else {
            ZStack {
                Color(.white).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 200)
                        .foregroundColor(Color("myPrimaries"))
                        .scaleEffect(size)
                        .opacity(opacity)
                        .offset(y: y)
                        .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
                }
            }
            .onAppear {
                // Configurar managers primero
                UserManager.shared.configure(with: modelContext)
                RecordManager.shared.configure(with: modelContext)
                
                // Verificar permisos de ubicación
                LocationManager.shared.checkAuthorizationStatus()
                
                // Animación de entrada
                withAnimation(.easeOut(duration: 1.2)) {
                    self.size = 1.0
                    self.opacity = 1.0
                    self.y = 0
                }
                
                // Transición a la siguiente pantalla
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private var currentUser: String? {
        return UserManager.shared.getAuthToken
    }
}

#Preview {
    SplashView()
}
