//
//  SplashScreen.swift
//  QGS
//
//  Created by Edin Martinez on 8/11/24.
//

import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var size = 0.5
    @State private var opacity = 0.5
    
    let accessToken = UserDefaults.standard.string(forKey: "accessToken")
    let datecreatAt = UserDefaults.standard.string(forKey: "createdAt")
   @State private var locationH = LocationManager()
  // let persistenceController = PersistenceController.shared
    
    var body: some View {
        if isActive {
            
            if accessToken != nil && datecreatAt == currentDateString {
                HomeRecord()
                  //  .environment(\.managedObjectContext, persistenceController.viewContext)
             }else{
                 Login()
                   //  .environment(\ .managedObjectContext, persistenceController.viewContext)
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
}





#Preview {
    SplashView()
}
