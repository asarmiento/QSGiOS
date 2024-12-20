class RecordManager: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    @Published var lastResponse: WorkTimeResponse?
    
    func registerWorkTime(workType: Int, projectId: Int, latitude: String, longitude: String, address: String) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        let workData: [String: Any] = [
            "work_type_id": workType,
            "project_id": projectId,
            "latitude": latitude,
            "longitude": longitude,
            "address": address
        ]
        
        do {
            let response = try await APIServiceRecord.shared.storeWorkTime(workData: workData)
            
            await MainActor.run {
                self.lastResponse = response
                self.isLoading = false
                print("Registro exitoso: \(response.message)")
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
                print("Error al registrar: \(error.localizedDescription)")
            }
        }
    }
} 