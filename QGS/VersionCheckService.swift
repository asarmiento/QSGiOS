import Foundation

struct BuildVersion: Codable {
    let success: Bool
    let version: String
}

class VersionCheckService {
    static let shared = VersionCheckService()
    private let apiURL = "https://api.friendlypayroll.net/api/build-apple"
    
    func checkForUpdate() async throws -> (currentVersion: String, latestVersion: String, needsUpdate: Bool) {
        guard let url = URL(string: apiURL) else {
            throw VersionError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw VersionError.invalidResponse
        }
        
        let buildVersion = try JSONDecoder().decode(BuildVersion.self, from: data)
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        
        return (
            currentVersion: currentVersion,
            latestVersion: buildVersion.version,
            needsUpdate: compareVersions(current: currentVersion, latest: buildVersion.version)
        )
    }
    
    private func compareVersions(current: String, latest: String) -> Bool {
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        let latestComponents = latest.split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<min(currentComponents.count, latestComponents.count) {
            if currentComponents[i] < latestComponents[i] {
                return true
            } else if currentComponents[i] > latestComponents[i] {
                return false
            }
        }
        
        return currentComponents.count < latestComponents.count
    }
}

enum VersionError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL de verificación de versión no válida"
        case .invalidResponse:
            return "No se pudo obtener respuesta del servidor"
        case .invalidData:
            return "Los datos recibidos no son válidos"
        }
    }
} 