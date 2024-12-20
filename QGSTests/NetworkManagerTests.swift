import XCTest
@testable import QGS

class NetworkManagerTests: XCTestCase {
    var networkManager: NetworkManager!
    
    override func setUp() {
        super.setUp()
        networkManager = NetworkManager.shared
    }
    
    override func tearDown() {
        networkManager = nil
        super.tearDown()
    }
    
    func testInvalidURL() async {
        do {
            let _: UserModel = try await networkManager.request("invalid url")
            XCTFail("Debería haber fallado con URL inválida")
        } catch {
            XCTAssertTrue(error is NetworkError)
            if case NetworkError.invalidURL = error {
                // Test passed
            } else {
                XCTFail("Error incorrecto: \(error)")
            }
        }
    }
    
    // Más tests...
} 