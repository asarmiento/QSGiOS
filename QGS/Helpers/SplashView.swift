//
//  SplashScreen.swift
//  QGS
//
//  Created by Anwar Sarmiento on 8/11/24.
//

import SwiftUI

struct SplashView: View {
    @Environment(\.modelContext) private var context
    @State private var isActive = false
    @State private var size = 0.5
    @State private var opacity = 0.5
   
    let accessToken = UserManager.shared.authToken
    let datecreatAt = UserDefaults.standard.string(forKey: "createdAt")
   @State private var locationH = LocationViewController()
 //  let persistenceController = PersistenceController.shared
    
    var body: some View {
      
                 
        if isActive {
            if currentUser != nil {
                HomeRecord()
                    .navigationBarBackButtonHidden(false)  .onAppear {
                        // Configurar el UserManager con el contexto
                        UserManager.shared.configure(with: context)
                        RecordManager.shared.configure(with: context)
                    }
             }else{
                 Login()  .onAppear {
                     // Configurar el UserManager con el contexto
                     UserManager.shared.configure(with: context)
                     RecordManager.shared.configure(with: context)
                 }
             }
        }
        else{
            VStack{
              VStack{
                    Image("QGS-Branding-01")
                        .resizable().scaledToFit()
                        .frame(width: 300, height: 200)
                        .foregroundColor(.myPrimary)
                       
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear{
                    withAnimation(.easeIn(duration:1.2)){
                        self.size = 1
                        self.opacity = 1.0
                    }
                }
            }
            .onAppear{
                UserManager.shared.configure(with:  context)
                RecordManager.shared.configure(with: context)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
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
        return UserManager.shared.authToken
    }
}





#Preview {
    SplashView()
}
