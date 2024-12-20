/*
 *
 */

import SwiftUI
import UIKit
import CoreData
import CoreLocation

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
            ZStack {
                
                Color.myPrimary.ignoresSafeArea()
                
                Image("QGS-Branding-02")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 370)
                    .offset(y:-300)
                
                ZStack{
                    Color.white.frame( height: 760)
                        .shadow(radius: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 70).offset(y: 80))
                        .frame(width: 400, height: 660)
                        .offset(y:140)
                        .edgesIgnoringSafeArea(.horizontal)
                    
                    
                    VStack(alignment: .center, spacing:40) {
                        
                        VStack(spacing: 25) {
                            
                            Group{
                                // Email and Password fields
                                CustomTF(sfIcon: "at", hint: "Email", value: $email)
                                
                                CustomTF(sfIcon: "lock", hint: "Password", isPassword: true, value: $password)
                                    .padding(.top, 5)
                                
                            }
                            .padding(12)
                            .frame(width: 350, height: 60)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(10)
                            
                            Button(action: {
                                errorMessage = ""
                                isLoading.toggle()
                                login()
                            },label  : {
                                Text("Iniciar Sesión").foregroundStyle(.white)
                                
                            }).disabled(isLoading)
                                .frame(width: 250, height: 60)
                                .background(Color.myPrimary).border(Color.myPrimary, width:1 )
                                .cornerRadius(10)
                                .fullScreenCover(isPresented: $isLoginSuccessful){
                                    // dismiss()
                                    HomeRecord()
                                }
                            
                            if let errorMessage = errorMessage {
                                //  print(" linea 72 errorMessage")
                                Text(errorMessage)
                                    .foregroundStyle(.red)
                            }
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(2)
                                    .padding(.top, 50)
                            }
                        }.offset(y:100).ignoresSafeArea()
                        VStack {
                           
                            Text("Quality Group Services v\(version())").font(.system(size: 12))
                            
                        }.offset(y:230).foregroundStyle(Color.gray)
                    }
                }.shadow(radius: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 20).offset(y: 80))
                    .frame(width: 400, height: 600)
                
            }
            .navigationBarHidden(false)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "")
            }
            .navigationDestination(isPresented: $isLoginSuccessful) {
                HomeRecord()
            }
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
            isLoading = false
            
            switch result {
            case .success(let response):
                if response.status {
                    UserManager.shared.configure(with: modelContext)
                    UserManager.shared.saveUser(from: response)
                    DispatchQueue.main.async {
                        self.isLoginSuccessful = true
                        self.navigateToWelcomeScreen()
                    }
                } else {
                    errorMessage = response.message
                    showError = true
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    func navigateToWelcomeScreen() {
        isLoginSuccessful = true
    }
    
    
}

//#Preview {
//    Login()
//}
