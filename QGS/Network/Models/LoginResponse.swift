import Foundation

struct LoginResponse: Codable {
    let status: Bool
    let message: String
    let user: UserResponse
    let name: String
    let sysconf: Int
    let email: String
    let token: String
    
    struct UserResponse: Codable {
        let id: Int
        let name: String
        let type: String
        let sysconf_id: Int
        let code: String
        let email: String
        let created_at: String
        let updated_at: String
        let employee: EmployeeResponse
        let sysconfs: [SysconfResponse]
        
        struct EmployeeResponse: Codable {
            let id: Int
            let card: String
            let type_of_card: String
            let name: String
            let vacation: Int
            let email: String
            let phone: String
            let user_id: Int
        }
        
        struct SysconfResponse: Codable {
            let id: Int
            let name: String
            let card: String?
            let url: String
            let type_card: String?
            let phone: String?
            let email: String?
            let created_at: String?
            let updated_at: String?
            let pivot: PivotResponse
            
            struct PivotResponse: Codable {
                let user_id: Int
                let sysconf_id: Int
            }
        }
    }
} 