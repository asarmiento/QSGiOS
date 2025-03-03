//
//  EmployeeCodable.swift
//  QGS
//
//  Created by Edin Martinez on 12/9/24.
//

import Foundation

struct EmployeeCodable: Codable, Identifiable {
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
    let status: Int
    let createdAt: String?
    let updatedAt: String?
    let typeWork: TypeWork?
    let user: User?
    
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
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case typeWork = "type_work"
        case user
    }
}

struct TypeWork: Codable {
    let id: Int
    let employeeId: Int
    let workTypeId: Int
    let createdAt: String?
    let updatedAt: String?
    let workType: WorkType?
    
    enum CodingKeys: String, CodingKey {
        case id
        case employeeId = "employee_id"
        case workTypeId = "work_type_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case workType = "work_type"
    }
}

struct WorkType: Codable {
    let id: Int
    let name: String
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct User: Codable {
    let id: Int
    let name: String
    let type: String
    let sysconfId: Int
    let code: String
    let email: String
    let emailVerifiedAt: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case sysconfId = "sysconf_id"
        case code
        case email
        case emailVerifiedAt = "email_verified_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
