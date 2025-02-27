import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeRecord()
                .tabItem {
                    Image(systemName: "clock")
                    Text(NSLocalizedString("Registro", comment: ""))
                }
                .tag(0)
            
            ListRecordTotals()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text(NSLocalizedString("Total", comment: ""))
                }
                .tag(1)
            
            ListRecordDetails()
                .tabItem {
                    Image(systemName: "doc.text")
                    Text(NSLocalizedString("Detalles", comment: ""))
                }
                .tag(2)
            
            ConfigurationView()
                .tabItem {
                    Image(systemName: "gear")
                    Text(NSLocalizedString("Configuración", comment: ""))
                }
                .tag(3)
        }
    }
} 