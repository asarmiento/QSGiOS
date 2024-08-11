//
//  ContentView.swift
//  QGS
//
//  Created by Edin Martinez on 7/24/24.
//



import SwiftUI
import SwiftData


struct Login: View {
    @Environment(\.modelContext) var modelContext
    @State private var email = ""
    @State private var password = ""
    @State private var wrongEmail = 0
    @State private var wrongPassword = 0
    @State private var showingLoginScreen = false
    @StateObject var creaturesVM = LoginHttpPost()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.myPrimary.ignoresSafeArea()
                
                Circle().scale(1.6)
                    .foregroundColor(.white.opacity(0.15))
                Circle().scale(1.4)
                    .foregroundColor(.white.opacity(0.15))
                
                Circle().scale(1.2).foregroundColor(.white)
                
                VStack(spacing: 15) {
                    Text("Login QGS").font(.largeTitle)
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
                    
                    Button("Login") {
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
                }).isDetailLink(false)
            }
            .navigationBarHidden(false)
            
        }
    }
}


