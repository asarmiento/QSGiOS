//
//  HomeRecord.swift
//  QGS
//
//  Created by Edin Martinez on 7/31/24.
//



import SwiftUI
import CoreLocation
import CoreLocationUI
import SwiftData


struct HomeRecord: View {
    
    @Query private var userModel: [UserModel]
    @State private var user: UserModel?
    @State private var isLoading = true  // Indicador de carga
    @State private var errorMessage: String?  // Para manejar errores
    // Variables de pantalla
    @StateObject private var creaturesVM = RecordHttpPost()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo y diseño general
                Color(.systemBackground).edgesIgnoringSafeArea(.all)
                // Encabezado
                if let user = user {
                    //  print(" prueba user \(user.email)")
                    HeadSecondary(title: "Bienvenido(a): \(user.name) ")
                    // .padding(.top, 40)
                } else {
                    HeadSecondary(title: "Entrada o Salida ")
                    //    .padding(.top, 40)
                }
                
                VStack {
                    
                    
                    // Mensaje informativo
                    Text("Debe presionar el boton de entrada o salida, para poder registrar su ingreso o su salida del trabajo")
                        .font(.system(size: 20))
                        .font(.title3)
                        .foregroundColor(Color.myPrimary)
                        .padding()
                        .multilineTextAlignment(.center)
                        .frame(width: 370, height: 150, alignment: .center)
                   
                    // Contenido principal
                    VStack {
                        BoxGPS()
                        
                        // Botones de acción
                        HStack {
                            ButtonIn()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        // Botones adicionales (Detalles y Totales)
                        HStack {
                            Group {
                                NavigationLink("Ver Detalles") {
                                    ListRecordDetails()
                                }
                                .frame(width: 150, height: 50)
                                .background(Color.myPrimary)
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                
                                NavigationLink("Ver Totales") {
                                    // Acción para ver totales
                                    ListRecordTotals()
                                }
                                .frame(width: 150, height: 50)
                                .background(Color.myPrimary)
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
            }
            .onAppear {
                loadUserData()
            }
        }
    }
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    // Función para cargar los datos del usuario
    func loadUserData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if let firstUser = try await fetchFirstUser() {
                    self.user = firstUser
                } else {
                    self.errorMessage = "No se encontró ningún usuario."
                }
            } catch {
                self.errorMessage = "Error al cargar los datos del usuario: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    // Función asincrónica para obtener el primer usuario
    func fetchFirstUser() async throws -> UserModel? {
        if let firstUser = userModel.first {
            return firstUser
        }
        return nil
    }
    
    func storeAccessToken() {
        UserDefaults.standard.set(user?.token, forKey: "accessToken")
    }
    func storeAccessEmployeeId() {
        UserDefaults.standard.set(user?.employeeId, forKey: "employeeId")
    }
 
}


#Preview {
    HomeRecord()
}



