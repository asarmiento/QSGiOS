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
    @State private var email: String = "asarmiento@sistemasamigableslatam.com"
    @State private var password: String = "secret"
    @State private var errorMessage: String? = nil
    
    
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
                                isLoading.toggle()
                                login()
                            },label  : {
                                
                                //        })
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
                            Text("Quality Group Services").font(.system(size: 9))
                            
                        }.offset(y:230).foregroundStyle(Color.gray)
                    }
                }.shadow(radius: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 20).offset(y: 80))
                    .frame(width: 400, height: 600)
                
            }
            .navigationBarHidden(false)
        }
    }
    
    func login() {
        APIService.shared.login(email: email, password: password) { result in
            
            switch result {
            case .success(let response):
                if response.status {
                    // Guardar los datos
                   // saveUserData(from: response)
                    
                    print("==Guardando los datos== \(response)")
                    UserManager.shared.saveUser(from: response)
                    // Redirigir a la pantalla de bienvenida
                    DispatchQueue.main.async {
                        isLoginSuccessful = true
                        // Usar el NavigationLink para navegar
                        // HomeRecord.init()
                        navigateToWelcomeScreen()
                        print("Login successful")
                    }
                } else {
                    DispatchQueue.main.async {
                        print("Error esta llegando a seccion case: ")
                        errorMessage = response.message
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    print("Error esta llegando a seccion case: \(error)")
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func navigateToWelcomeScreen() {
        // Navegar a la pantalla de bienvenida
        isLoginSuccessful = true
        //
        print("NavigationDestination isPresented: \(isLoginSuccessful)")
      //  dismiss()
    }
    

}

//#Preview {
//    Login()
//}
