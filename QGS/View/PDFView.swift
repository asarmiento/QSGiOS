import SwiftUI
import PDFKit
import UIKit

// Vista nativa de PDF usando PDFKit en lugar de WKWebView
struct NativePDFView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    // Función estática para verificar si el usuario tiene acceso
   
    func makeUIView(context: Context) -> PDFKit.PDFView {
        let pdfView = PDFKit.PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true)
        pdfView.pageBreakMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        pdfView.backgroundColor = UIColor.systemBackground
        
        // Configurar el delegado para manejar eventos
        context.coordinator.pdfView = pdfView
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFKit.PDFView, context: Context) {
        isLoading = true
        
        // Cargar el PDF en segundo plano para evitar bloqueos
        DispatchQueue.global(qos: .userInitiated).async {
            // Descargar el PDF
            do {
                let data = try Data(contentsOf: url)
                let document = PDFKit.PDFDocument(data: data)
                
                DispatchQueue.main.async {
                    pdfView.document = document
                    isLoading = false
                    
                    if document == nil {
                        print("Error al cargar el PDF desde \(url.absoluteString)")
                    } else {
                        print("PDF cargado correctamente")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    print("Error al descargar el PDF: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: NativePDFView
        var pdfView: PDFKit.PDFView?
        
        init(_ parent: NativePDFView) {
            self.parent = parent
        }
    }
}

struct PDFViewContainer: View {
    @State private var showShareSheet = false
    @State private var pdfData: Data?
    @State private var isLoading = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var pdfURL: URL?
    @State private var pdfDocument: PDFKit.PDFDocument?
    @State private var hasAccess: Bool = false
    
    static func userHasAccess() -> Bool {
        // Verificar si el tipo de usuario no es "employee"
        if let userType = UserManager.shared.userType {
            return userType != "employee"
        }
        return false
    }
    
    // URL del PDF
    let pdfURLString = "https://api.friendlypayroll.net/weekly-hours"
    
    var body: some View {
        NavigationStack {
            ZStack {
                if hasAccess {
                    if let url = URL(string: pdfURLString) {
                        NativePDFView(url: url, isLoading: $isLoading)
                            .navigationTitle("Reporte Semanal")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    HStack(spacing: 16) {
                                        Button(action: downloadPDF) {
                                            Label("Descargar", systemImage: "arrow.down.doc")
                                        }
                                        
                                        Button(action: printPDF) {
                                            Label("Imprimir", systemImage: "printer")
                                        }
                                        
                                        Button(action: sharePDF) {
                                            Label("Compartir", systemImage: "square.and.arrow.up")
                                        }
                                    }
                                }
                            }
                            .onAppear {
                                // Precargar el PDF para las operaciones
                                loadPDFData()
                            }
                    } else {
                        Text("URL inválida")
                            .foregroundColor(.red)
                    }
                    
                    if isLoading {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                        
                        ProgressView("Cargando PDF...")
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                } else {
                    ZStack {
                        // Marca de agua
                        Image("QGS-Branding-01")
                            .resizable()
                            .scaledToFit()
                            .opacity(0.1)
                        
                        // Mensaje de acceso denegado
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.shield")
                                .font(.system(size: 60))
                                .foregroundColor(.red)
                            
                            Text("Acceso Denegado")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("No tienes permisos para acceder a esta sección.")
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        .padding()
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Información"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("Aceptar"))
                )
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = pdfURL {
                    ActivityViewController(activityItems: [url])
                } else if let data = pdfData {
                    ActivityViewController(activityItems: [data])
                }
            }
            .onAppear {
                // Verificar si el usuario tiene acceso
                checkUserAccess()
                hasAccess = PDFViewContainer.userHasAccess()
                if hasAccess {
                    loadPDFData()
                }
            }
            .refreshable {
                if hasAccess {
                    loadPDFData()
                }
            }
        }
    }
    
    private func checkUserAccess() {
        // Verificar el tipo de usuario desde UserManager
        if let userType = UserManager.shared.userType {
            // Si el usuario es administrador o supervisor, tiene acceso
            hasAccess = userType.lowercased() != "empleado"
        } else {
            hasAccess = false
        }
    }
    
    private func loadPDFData() {
        guard let url = URL(string: pdfURLString) else {
            alertMessage = "URL inválida"
            showAlert = true
            return
        }
        
        // Solo cargar si aún no tenemos los datos
        if pdfData == nil && pdfURL == nil {
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error al cargar PDF: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let data = data else {
                        print("No se pudieron obtener datos del PDF")
                        return
                    }
                    
                    // Guardar los datos para uso posterior
                    pdfData = data
                    
                    // Guardar temporalmente en caché
                    let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                    let fileName = "cached_report_\(Int(Date().timeIntervalSince1970)).pdf"
                    let fileURL = cacheDirectory.appendingPathComponent(fileName)
                    
                    do {
                        try data.write(to: fileURL)
                        pdfURL = fileURL
                        pdfDocument = PDFKit.PDFDocument(data: data)
                    } catch {
                        print("Error al guardar PDF en caché: \(error.localizedDescription)")
                    }
                }
            }
            
            task.resume()
        }
    }
    
    private func downloadPDF() {
        isLoading = true
        
        func performDownload() {
            if let existingData = pdfData {
                saveToDocuments(data: existingData)
            } else {
                guard let url = URL(string: pdfURLString) else {
                    isLoading = false
                    alertMessage = "URL inválida"
                    showAlert = true
                    return
                }
                
                let task = URLSession.shared.dataTask(with: url) { data, response, error in
                    DispatchQueue.main.async {
                        isLoading = false
                        
                        if let error = error {
                            alertMessage = "Error al descargar: \(error.localizedDescription)"
                            showAlert = true
                            return
                        }
                        
                        guard let data = data else {
                            alertMessage = "No se pudo obtener los datos del PDF"
                            showAlert = true
                            return
                        }
                        
                        // Guardar los datos para uso posterior
                        pdfData = data
                        
                        saveToDocuments(data: data)
                    }
                }
                
                task.resume()
            }
        }
        
        func saveToDocuments(data: Data) {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "reporte_semanal_\(Int(Date().timeIntervalSince1970)).pdf"
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            do {
                try data.write(to: fileURL)
                pdfURL = fileURL
                
                isLoading = false
                alertMessage = "PDF guardado como '\(fileName)'"
                showAlert = true
            } catch {
                isLoading = false
                alertMessage = "Error al guardar: \(error.localizedDescription)"
                showAlert = true
            }
        }
        
        performDownload()
    }
    
    private func printPDF() {
        isLoading = true
        
        func performPrint() {
            if let existingData = pdfData, let pdfDoc = PDFKit.PDFDocument(data: existingData) {
                printDocument(pdfDoc: pdfDoc)
            } else {
                guard let url = URL(string: pdfURLString) else {
                    isLoading = false
                    alertMessage = "URL inválida"
                    showAlert = true
                    return
                }
                
                let task = URLSession.shared.dataTask(with: url) { data, response, error in
                    DispatchQueue.main.async {
                        isLoading = false
                        
                        if let error = error {
                            alertMessage = "Error al preparar impresión: \(error.localizedDescription)"
                            showAlert = true
                            return
                        }
                        
                        guard let data = data else {
                            alertMessage = "No se pudo obtener los datos para imprimir"
                            showAlert = true
                            return
                        }
                        
                        // Guardar los datos para uso posterior
                        pdfData = data
                        
                        if let pdfDoc = PDFKit.PDFDocument(data: data) {
                            printDocument(pdfDoc: pdfDoc)
                        } else {
                            alertMessage = "No se pudo crear el documento PDF para imprimir"
                            showAlert = true
                        }
                    }
                }
                
                task.resume()
            }
        }
        
        func printDocument(pdfDoc: PDFKit.PDFDocument) {
            let printController = UIPrintInteractionController.shared
            let printInfo = UIPrintInfo(dictionary: nil)
            printInfo.jobName = "Reporte Semanal"
            printInfo.outputType = .general
            printController.printInfo = printInfo
            
            // Usar el documento PDF directamente
            printController.printingItem = pdfDoc.dataRepresentation()
            
            printController.present(animated: true) { (controller, completed, error) in
                isLoading = false
                
                if let error = error {
                    alertMessage = "Error de impresión: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
        
        performPrint()
    }
    
    private func sharePDF() {
        isLoading = true
        
        func performShare() {
            if pdfURL != nil {
                isLoading = false
                showShareSheet = true
            } else if let existingData = pdfData {
                // Guardar temporalmente para compartir
                let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                let fileName = "temp_share_\(Int(Date().timeIntervalSince1970)).pdf"
                let fileURL = cacheDirectory.appendingPathComponent(fileName)
                
                do {
                    try existingData.write(to: fileURL)
                    pdfURL = fileURL
                    isLoading = false
                    showShareSheet = true
                } catch {
                    isLoading = false
                    alertMessage = "Error al preparar para compartir: \(error.localizedDescription)"
                    showAlert = true
                }
            } else {
                guard let url = URL(string: pdfURLString) else {
                    isLoading = false
                    alertMessage = "URL inválida"
                    showAlert = true
                    return
                }
                
                let task = URLSession.shared.dataTask(with: url) { data, response, error in
                    DispatchQueue.main.async {
                        isLoading = false
                        
                        if let error = error {
                            alertMessage = "Error al preparar para compartir: \(error.localizedDescription)"
                            showAlert = true
                            return
                        }
                        
                        guard let data = data else {
                            alertMessage = "No se pudo obtener los datos para compartir"
                            showAlert = true
                            return
                        }
                        
                        // Guardar los datos para uso posterior
                        pdfData = data
                        
                        // Guardar temporalmente para compartir
                        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                        let fileName = "temp_share_\(Int(Date().timeIntervalSince1970)).pdf"
                        let fileURL = cacheDirectory.appendingPathComponent(fileName)
                        
                        do {
                            try data.write(to: fileURL)
                            pdfURL = fileURL
                            showShareSheet = true
                        } catch {
                            alertMessage = "Error al preparar para compartir: \(error.localizedDescription)"
                            showAlert = true
                        }
                    }
                }
                
                task.resume()
            }
        }
        
        performShare()
    }
}

// Estructura para manejar la hoja de compartir
struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}

// Clase auxiliar para manejar documentos PDF
class PDFDocument: NSObject {
    private var data: Data
    
    init?(data: Data) {
        self.data = data
        super.init()
    }
    
    func dataRepresentation() -> Data {
        return data
    }
} 
