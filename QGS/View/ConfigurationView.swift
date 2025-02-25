import SwiftUI

struct ConfigurationView: View {
    var openInPreview: () -> Void = {}
    var saveAsPDF: () -> Void = {}
    @State private var showPDFView = false
    @State private var showTimeRecordView = false

    var body: some View {
        NavigationStack {
        VStack {
            if let user = getUser {
                // Menú accesible solo para usuarios que no son "Colaborador"
                if user.type != "employee" {

                    Section {
                        Button(
                            "Lista de Contactos", systemImage: "person.circle"
                        ) {
                            showTimeRecordView = true
                        }
                        Button(
                            "Reporte PDF Quincenal",
                            systemImage: "person.circle"
                        ) {
                            showPDFView = true
                        }

                    }
                    .navigationDestination(isPresented: $showPDFView) {
                        PDFView(
                            url: URL(
                                string:
                                    "https://api.friendlypayroll.net/weekly-hours"
                            )!)
                    }
                    .navigationDestination(isPresented: $showTimeRecordView) {
                        TimeRecordsView()
                    }
                    .buttonStyle(.bordered)
                }else{
                    Text("No tiene permisos para acceder a esta sección.")
                }
            }
        }
        .padding()
    }
    }
    private var getUser: UserModel? {
        return UserManager.shared.getUser()
    }
}
