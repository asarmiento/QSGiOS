//
//  ContentView.swift
//  QGS
//
//  Created by Edin Martinez on 7/24/24.
//
import UIKit
import SwiftUI
import SwiftData

struct Login: View {
    @Environment(\.modelContext) var modelContext
    @State private var email = "asarmiento@sistemasamigableslatam.com"
    @State private var password = "secret"
    @State private var wrongEmail = 0
    @State private var wrongPassword = 0
    @State private var showingLoginScreen = false
    @StateObject var creaturesVM = LoginHttpPost()
    @State var homeRecord = HomeRecord()
    
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
                    
                   
                    Button("Login"){
                        creaturesVM.executeAPI(email: email, password: password)
                      
                       
                      
                        
                        }.frame(width: 300,height: 50)
                            .background(.red)
                            .buttonStyle(.bordered)
                            .tint(.black)
                            .border(Color.black, width: 0.02)
                        Text("Registra tu ingreso y Salida")
                            .font(.footnote)
                            .underline( )
                            .foregroundStyle(.tertiary)
                            .padding()
                    
             
                }
            }
        }
        .navigationBarHidden(false)
    }


}

    
    #Preview {
        Login()
    }
    


struct Previews_Login_LibraryContent: LibraryContentProvider {
    var views: [LibraryItem] {
        LibraryItem(/*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/)
    }
}
