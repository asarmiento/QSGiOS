//
//  HomeRecord.swift
//  QGS
//
//  Created by Anwar Sarmiento on 7/31/24.
//


import Foundation
import SwiftUI
import SwiftData
import CoreLocation
import FirebaseAnalytics
// Si LocationManager está en un módulo separado:
// import Managers

struct HomeRecord: View {
    
    @Environment(\.modelContext) private var context: ModelContext
    @StateObject private var locationManager = LocationViewController.shared
    @State private var showLocationAlert = false
    @State private var isLoading: Bool = false
    
    // Indicador de carga
    @State private var errorMessage: String?  // Para manejar errores
    // Variables de pantalla
    // @StateObject private var creaturesVM = RecordHttpPost()
    
    @State private var isButtonDisabled = false
    @State private var hasCheckedLocation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo y diseño general
                Color(.white).edgesIgnoringSafeArea(.all)
                // Encabezado
                //  Text(\(getUser))
                
                if let user = getUser {
                    
                    HeadSecondary(title: "Bienvenido(a): \(user.name)")
                    
                } else {
                    HeadSecondary(title: "Entrada o Salida")
                    
                }
                
                VStack {
                    // Mensaje informativo
                    Text(NSLocalizedString("Debe presionar el boton de entrada o salida, para poder registrar su ingreso o su salida del trabajo",
                                           comment: "Mensaje para indicar al usuario qué hacer"))
                    .font(.system(size: 18))
                    .font(.title3)
                    .foregroundColor(Color("myPrimaries"))
                    .padding()
                    .multilineTextAlignment(.center)
                    .frame(width: 370, height: 200, alignment: .center)
                    
                    // Contenido principal
                    VStack {
                        BoxGPS()
                        
                        
                        // Botones de acción
                        HStack {
                            ButtonIn(isLoading: $isLoading)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .environment(\.modelContext, context)
                                .onTapGesture {
                                    logCheckInEvent(type: "check_in")
                                }
                        }
                        
                    }
                    .frame(maxWidth: .infinity)
                    .padding(-10)
                    
                    // Mostrar mensaje de error si hay uno
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding(.top, 10)
                    }
                    
                    // Mostrar indicador de carga si estamos esperando datos
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(2)
                            .padding(.top, 50)
                    }
                    
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center).offset(y:90)
                .alert(isPresented: $showLocationAlert) {
                    Alert(
                        title: Text(NSLocalizedString("Permiso de Localización", comment: "")),
                        message: Text(NSLocalizedString("La aplicación necesita acceso a tu ubicación", comment: "")),
                        primaryButton: .default(Text(NSLocalizedString("Abrir Configuración", comment: ""))) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        },
                        secondaryButton: .cancel(Text(NSLocalizedString("Cancelar", comment: "")))
                    )
                }
                VStack {
                    #if QGS_TARGET
                    Text(String(format: NSLocalizedString("Quality Group Services v%@", comment: ""), version()))
                        .font(.system(size: 12))
                        #elseif FRIENDLY_TARGET
                    Text(String(format: NSLocalizedString("Friendly Systems Group v%@", comment: ""), version()))
                        .font(.system(size: 12))
                    #elseif MCS_TARGET
                    Text(String(format: NSLocalizedString("Martinez Cleaning Service v%@", comment: ""), version()))
                        .font(.system(size: 12))
                    #endif
                    
                }.foregroundStyle(Color.gray).offset(y:400)
                
                
            }
            .onAppear {
                logScreenView()
                RecordManager.shared.configure(with: context) // <-- Configura el contexto aquí
                if !hasCheckedLocation {
                    LocationManager.shared.checkAuthorizationStatus()
                    hasCheckedLocation = true
                }
                if locationManager.isAuthorized {
                    LocationManager.shared.startUpdatingLocation()
                }
            }.onChange(of: locationManager.isAuthorized) { oldValue, newValue in
                if newValue {
                    LocationManager.shared.startUpdatingLocation()
                } else {
                    LocationManager.shared.stopUpdatingLocation()
                    showLocationAlert = true
                }
            }
            
        }
        
    }
    
    
    func version() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
        //   let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "N/A"
        return "\(version) "//(\(build))
    }
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    private var authToken: String? {
        return  UserManager.shared.getAuthToken
    }
    private var getUser: UserModel? {
        return  UserManager.shared.getUser()
    }
    
    private var employeeId: String? {
        
        return UserManager.shared.getEmployeeId
    }
    
    private func logCheckInEvent(type: String) {
        Analytics.logEvent("employee_check", parameters: [
            "type": type,
            "employee_id": UserManager.shared.getEmployeeId ?? "",
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    private func logScreenView() {
        let user = getUser
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: "Home",
            AnalyticsParameterScreenClass: "HomeRecord",
            "user_id": UserManager.shared.getEmployeeId ?? "unknown",
            "user_name": user?.name ?? "unknown",
            "has_user": user != nil ? "yes" : "no"
        ])
    }
    
}



#Preview {
    HomeRecord()
}



