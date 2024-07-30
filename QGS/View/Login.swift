//
//  ContentView.swift
//  QGS
//
//  Created by Edin Martinez on 7/24/24.
//

import SwiftUI

struct Login: View {
    @State private var email = ""
    @State private var password = ""
    @State private var wrongEmail = 0
    @State private var wrongPassword = 0
    @State private var showingLoginScreen = false
    
    
    var body: some View {
        NavigationView{
            ZStack{
                Color.myPrimary.ignoresSafeArea()
                
                
                Circle().scale(1.6)
                    .foregroundColor(.white.opacity(0.15))
                Circle().scale(1.4)
                    .foregroundColor(.white.opacity(0.15))
                
                Circle().scale(1.2).foregroundColor(.white)
                
                VStack(spacing:15){
                    Text("Login QGS").font(.largeTitle)
                        .bold()
                        .padding().foregroundColor(.myPrimary)
                    Group{
                        CustomTF(sfIcon: "at", hint: "Email", value: $email)
                        
                        CustomTF(sfIcon: "lock", hint: "Password", isPassword: true, value: $password)
                            .padding(.top, 5)
                        
                    }.padding(12)
                        .frame(width: 300, height:50)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius( 10)
                    
                    
              
                    
                }
            }
        }
        .navigationBarHidden(true)
    }
    func authenticateUser(email:String,password:String){
        if email.lowercased() == "anwarsarmiento@gmail.com"{
            wrongEmail = 0
            if password.lowercased() == "123"{
                wrongPassword = 0
                showingLoginScreen = true
            }else{
                wrongPassword = 2
            }
        }else{
            wrongEmail=2
        }
        
    }
}
    
    #Preview {
        Login()
    }
    

