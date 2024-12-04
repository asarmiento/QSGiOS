import SwiftUI
import UIKit
import CoreData
import CoreLocation

struct Login: View {
    @Environment(\.modelContext) private var context  // Inyección del contexto
    @Environment(\.dismiss) var dismiss
    
    @State private var isLoginSuccessful = false
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
                                login()
                            },label  : {
                                
                                //        })
                                Text("Iniciar Sesión").foregroundStyle(.white)
                                
                            })
                            .frame(width: 250, height: 60)
                            .background(Color.myPrimary).border(Color.myPrimary, width:1 )
                            .cornerRadius(10)
                            .fullScreenCover(isPresented: $isLoginSuccessful){
                                // dismiss()
                                HomeRecord()
                            }
                            
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .foregroundStyle(.red)
                            }
                            
                        }.offset(y:100).ignoresSafeArea()
                        VStack {
                            Text("Quality Group Services")
                            
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
                    saveUserData(from: response)
                    
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
                        errorMessage = response.message
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
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
        dismiss()
    }
    
    func saveUserData(from response: LoginResponse) {
        // Crear una nueva instancia del modelo User
        let user = UserModel(
            name: response.user.name,
            email: response.user.email,
            token: response.token,
            employeeId: response.user.employee.id,
            sysconf: response.sysconf
        )
        
        do {
            // Insertar el usuario en el contexto (context es inyectado automáticamente por SwiftUI)
            try context.insert(user)
            
            // Guardar los cambios
            try context.save()
        } catch {
            print("Error saving user data: \(error)")
        }
    }
    
    
    
    
}

#Preview {
    Login()
}
