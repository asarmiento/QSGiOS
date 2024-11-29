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
    @Environment(\.modelContext) var modelContext
    @Query(sort: \UserModel.id) var userModel: [UserModel] 
    // Variables de pantalla
    @StateObject private var locationManager = LocationManager()
    @StateObject private var creaturesVM = RecordHttpPost()
    var users : UserModel
    var body: some View {
        NavigationStack {
            ZStack {
//                let user = modelContext.f
                HeadSecondary(title: "Entrada o Salida \(String(describing: "user?.name"))")
                VStack{
                    Text("Debe presionar el boton de entrada o salida, para poder registrar su ingreso o su salida del trabajo").font(.system(size: 20)).font(.title3).foregroundStyle(Color.myPrimary).padding(10).frame(width:370,height: 150,alignment: .center)
                   VStack() {
                        BoxGPS()
                       HStack{
                            
                              
                            ButtonIn()
                            
                            
                           
                        }
                       HStack{
                           Group{
                                NavigationLink("Ver Detalles") {
                                    ListRecordDetails()
                                }
                                NavigationLink("Ver Totales") {
                                 //   ListRecordTotals()
                                }
                            }.padding()
                                .frame(width: 150, height: 50, alignment: .center)
                                .background(Color.red)
                                .cornerRadius(10)
                                .foregroundColor(.white)
                        }
                        NavigationLink(destination: ListDataRecords() ){ }
                       
                    }
                }
                .frame(alignment: .center)
            }
        }
        
    }
    private  var currentDateString: String {
       let formatter = DateFormatter()
       formatter.dateFormat = "yyyy-MM-dd"
       return formatter.string(from: Date())
   }
}


//#Preview {
//    HomeRecord(users: UserModel).modelContainer(for: [UserModel.self, RecordModel.self])
//}



