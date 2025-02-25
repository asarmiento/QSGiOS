import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeRecord()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Inicio")
                }

            ListRecordDetails()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Detalles")
                }

            ListRecordTotals()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Totales")
                }

            ConfigurationView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Configuración")
                }
        }
        .preferredColorScheme(.light)
    }
}
