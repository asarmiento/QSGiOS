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
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo y diseño general
                Color(.systemBackground).edgesIgnoringSafeArea(.all)
                // Encabezado
              //  Text(\(getUser))
                    
                if let user = getUser {
                    
                    HeadSecondary(title: "Bienvenido(a): \(user.name) ")
                   
                } else {
                    HeadSecondary(title: "Entrada o Salida ")
                    
                }
                
                VStack {
                    // Mensaje informativo
                    Text(NSLocalizedString("Debe presionar el boton de entrada o salida, para poder registrar su ingreso o su salida del trabajo",
                                           comment: "Mensaje para indicar al usuario qué hacer"))
                        .font(.system(size: 18))
                        .font(.title3)
                        .foregroundColor(Color.myPrimary)
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
                        }
                        // Botones adicionales (Detalles y Totales)
                        HStack {
                            Group {
                                NavigationLink("Horas Diarias") {
                                    ListRecordDetails()
                                }
                                .frame(width: 150, height: 50)
                                .background(Color.init(red: 0.333, green: 0.333, blue: 0.333))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                
                                NavigationLink("Horas Semanales") {
                                    // Acción para ver totales
                                    ListRecordTotals()
                                }
                                .frame(width: 150, height: 50)
                                .background(Color.init(red: 0.333, green: 0.333, blue: 0.333))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                            }
                        }
                        .padding()
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
                                            title: Text("Permiso de Localización"),
                                            message: Text("La aplicación necesita acceso a tu ubicación para realizar esta acción. Ve a Configuración para otorgar permisos."),
                                            primaryButton: .default(Text("Abrir Configuración")) {
                                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                                    UIApplication.shared.open(url)
                                                }
                                            },
                                            secondaryButton: .destructive(Text("Cancelar")) {
                                                        exit(0) // Cierra la aplicación
                                                    }
                                        )
                                    }
                VStack {
                   
                    Text(String(format: NSLocalizedString("Quality Group Services v%@", comment: ""), version()))
                        .font(.system(size: 12))

                    
                }.foregroundStyle(Color.gray).offset(y:400)
            }.onAppear {
                checkLocationAuthorization()
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
      return  UserManager.shared.authToken
    }
    private var getUser: UserModel? {
        return  UserManager.shared.getUser()
    }
    
    private var employeeId: String? {
        
        return UserManager.shared.employeeId
    }
    
    private func checkLocationAuthorization() {
        let status = locationManager.isAuthorized
           if status  {
               showLocationAlert = true
           } else {
               locationManager.requestLocationPermission()
           }
       }
    
}



#Preview {
    HomeRecord()
}



