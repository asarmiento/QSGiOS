//
//  EmployeeCodable.swift
//  QGS
//
//  Created by Edin Martinez on 12/9/24.
//



struct EmployeeCodable: Codable {
    let id: Int
    let card: String
    let typeOfCard: String
    let name: String
    let vacation: Int
    let email: String
    let phone: String
    let address: String?
    let provinceId: Int?
    let cantonId: Int?
    let districtId: Int?
    let maritalStatusId: Int?
    let nationalityId: Int?
    let userId: Int
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case card
        case typeOfCard = "type_of_card"
        case name
        case vacation
        case email
        case phone
        case address
        case provinceId = "province_id"
        case cantonId = "canton_id"
        case districtId = "district_id"
        case maritalStatusId = "marital_status_id"
        case nationalityId = "nationality_id"
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
