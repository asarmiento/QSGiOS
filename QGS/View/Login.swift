//
//  ContentView.swift
//  QGS
//
//  Created by Edin Martinez on 7/24/24.
//



import SwiftUI
import CoreData
import CoreLocation


struct Login: View {
    //Variables del Login
    @State private var email: String = "asarmiento@sistemasamigableslatam.com"
    @State private var password: String = "secret"
    @State private var wrongEmail: Bool = false
    @State private var wrongPassword: Bool = false
    @State private var showingLoginScreen = false
    @StateObject var creaturesVM = LoginHttpPost()
    @State private var locationH = LocationManager()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.myPrimary.ignoresSafeArea()
                
                Circle().scale(1.6)
                    .foregroundColor(.white.opacity(0.15))
                Circle().scale(1.4)
                    .foregroundColor(.white.opacity(0.15))
                
                Circle().scale(1.2).foregroundColor(.white)
                VStack() {
                    Image("QGS-Branding-01").resizable().scaledToFit().frame(width: 180)
                VStack(spacing: 15) {
                    Text("Login").font(.title2)
                        .bold()
                        .padding().foregroundColor(.myPrimary)
                    
                    Group {
                        CustomTF(sfIcon: "at", hint: "Email", value: $email)
                        
                        CustomTF(sfIcon: "lock", hint: "Password", isPassword: true, value: $password)
                            .padding(.top, 5)
                        
                    }.padding(12)
                        .frame(width: 300, height: 60)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(10)
                    
                   
                        
                    
                        Button("Iniciar Sesión ") {
                            locationH.requestLocationPermission()
                            creaturesVM.executeAPI(email: email, password: password)
                        }
                        .frame(width: 300, height: 50)
                        .background(.red)
                        .buttonStyle(.bordered)
                        .tint(.white)
                        .border(Color.black, width: 0.02)
                        Text("Registra tu ingreso y Salida")
                            .font(.footnote)
                            .underline()
                            .foregroundStyle(.tertiary)
                            .padding()
              
                    
                }
        
                NavigationLink(
                    destination: HomeRecord(),
                    isActive: $creaturesVM.loginSuccess
                , label: {
                    EmptyView()
                }).isDetailLink(false).navigationBarBackButtonHidden(true)
            }
            .navigationBarHidden(false)
            
        }
        }
    }
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    func validatePassword(_ password: String) -> Bool {
        return password.count >= 8
    }
    

}


