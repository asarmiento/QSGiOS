/*
 * Login.swift
 * QGS
 * 
 * Vista principal de login para todos los targets
 * Incluye funcionalidad de registro solo para FRIENDLY_TARGET
 */

import SwiftUI
import UIKit
import CoreData
import CoreLocation

#if FRIENDLY_TARGET
// Aseguramos que SignupView esté disponible para este target
// (Si SignupView está en otro módulo, podría necesitar un import específico)
#endif

struct Login: View {
    
    @State private var isLoginSuccessful = false
    @State private var isLoading = false  // Indicador de carga
    // Variables for Login
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String? = nil
    @State private var showError = false
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack() {
                    
                    Color("myPrimaries").ignoresSafeArea()
                    
                    // Logo ajustado más arriba
                    Image("Logo-White")
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(geometry.size.width * 0.8, 300))
                        .offset(y: -geometry.size.height * 0.35)
                   
                    // Caja blanca ajustada más abajo
                    ZStack {
                        Color.white
                            .shadow(radius: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 30))
                            .frame(width: min(geometry.size.width * 0.95, 400))
                            .frame(height: min(geometry.size.height * 0.5, 300))
                            .offset(y: geometry.size.height * 0.15)
                            .edgesIgnoringSafeArea(.horizontal)
                        
                        VStack(alignment: .center, spacing: geometry.size.height * 0.03) {
                            VStack(spacing: geometry.size.height * 0.02) {
                                Group {
                                    CustomTF(sfIcon: "at", hint: "Email", value: $email)
                                    
                                    CustomTF(sfIcon: "lock", hint: "Password", isPassword: true, value: $password)
                                        .padding(.top, 5)
                                }
                                .padding(12)
                                .frame(width: min(geometry.size.width * 0.85, 350))
                                .frame(height: min(geometry.size.height * 0.07, 50))
                                .background(Color.black.opacity(0.05))
                                .foregroundColor(Color.black)
                                .cornerRadius(10)
                                
                                Button(action: {
                                    errorMessage = ""
                                    isLoading.toggle()
                                    login()
                                }, label: {
                                    Text("Iniciar Sesión")
                                        .foregroundStyle(.white)
                                })
                                .disabled(isLoading)
                                .frame(width: min(geometry.size.width * 0.65, 250))
                                .frame(height: min(geometry.size.height * 0.07, 50))
                                .background(Color("myPrimaries"))
                                .cornerRadius(10)
                                .fullScreenCover(isPresented: $isLoginSuccessful) {
                                    MainTabView()
                                }
                                
                                if let errorMessage = errorMessage {
                                    Text(errorMessage)
                                        .foregroundStyle(.red)
                                        .font(.system(size: min(geometry.size.width * 0.04, 14)))
                                }
                                
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(1.5)
                                        .padding(.top, 20)
                                }
                                
                                #if FRIENDLY_TARGET
                                Button(action: {
                                    navigateToSignUp()
                                }) {
                                    Text("¿Eres nuevo? Regístrate aquí")
                                        .font(.system(size: 14))
                                        .foregroundColor(.myPrimary)
                                        .padding(.top, 10)
                                }
                                #endif
                            }
                            
                            // Versión ajustada al fondo de la caja blanca
                            VStack {
                                #if QGS_TARGET
                                Text("Quality Group Services In v\(version())")
                                    .font(.system(size: min(geometry.size.width * 0.03, 12)))
                                #elseif FRIENDLY_TARGET
                                Text("Friendly Check In v\(version())")
                                    .font(.system(size: min(geometry.size.width * 0.03, 12)))
                                #elseif MCS_TARGET
                                Text("Martinez Cleaning Service In v\(version())")
                                    .font(.system(size: min(geometry.size.width * 0.03, 12)))
                                #endif
                            }
                            .foregroundStyle(Color.gray)
                            .padding(.top, 10)
                        }
                        .offset(y: geometry.size.height * 0.15)
                    }
                }
            }
            .navigationBarHidden(false)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "")
            }
            .navigationDestination(isPresented: $isLoginSuccessful) {
                MainTabView()
            }
            
            #if FRIENDLY_TARGET
            .sheet(isPresented: $showSignUp) {
                /*
                 * Usando esta estructura para evitar tener que importar SignupView
                 * si hay problemas de accesibilidad entre targets
                 */
                NavigationView {
                    SignupView()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LoginSuccessful"))) { _ in
                // Cuando recibimos la notificación de registro exitoso, actualizamos el estado
                self.isLoginSuccessful = true
                self.showSignUp = false
            }
            #endif
        }
    }
    func version() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "N/A"
        return "\(version) (\(build))"
    }
    func login() {
        isLoading = true
        
        APIService.shared.login(email: email, password: password) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.status {
                        if let user = response.user {
                            print("Login exitoso, configurando UserManager")
                            UserManager.shared.configure(with: self.modelContext)
                            UserManager.shared.saveUser(from: response)
                            
                            // Añadir un pequeño retraso para permitir que se complete la configuración
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                print("Activando la navegación a la pantalla principal")
                                self.isLoginSuccessful = true
                            }
                        } else {
                            self.errorMessage = "Error al obtener datos del usuario"
                            self.showError = true
                        }
                    } else {
                        self.errorMessage = response.message
                        self.showError = true
                    }
                case .failure(let error):
                    if case NetworkError.apiError(let message) = error {
                        self.errorMessage = message
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    self.showError = true
                }
            }
        }
    }
    
    func navigateToWelcomeScreen() {
        // Esta función ya no es necesaria, pero la dejamos por compatibilidad
        // isLoginSuccessful = true
    }
    
    #if FRIENDLY_TARGET
    @State private var showSignUp = false
    
    func navigateToSignUp() {
        showSignUp = true
    }
    #endif
}

//#Preview {
//    Login()
//}
