import Foundation

struct LoginResponse: Codable {
    let status: Bool
    let message: String
    let user: UserResponse?
    let name: String?
    let sysconf: Int?
    let email: String?
    let token: String?
    
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
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(Int.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            type = try container.decode(String.self, forKey: .type)
            sysconf_id = try container.decode(Int.self, forKey: .sysconf_id)
            email = try container.decode(String.self, forKey: .email)
            created_at = try container.decode(String.self, forKey: .created_at)
            updated_at = try container.decode(String.self, forKey: .updated_at)
            employee = try container.decode(EmployeeResponse.self, forKey: .employee)
            sysconfs = try container.decode([SysconfResponse].self, forKey: .sysconfs)
            
            // Maneja 'code' tanto como Int o String
            if let codeInt = try? container.decode(Int.self, forKey: .code) {
                code = String(codeInt)
            } else {
                code = try container.decode(String.self, forKey: .code)
            }
        }
        
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