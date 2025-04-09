//
//  Endpoints.swift
//  QGS
//
//  Created by Edin Martinez on 11/20/24.
//

enum EndPoints {
    static let baseURL = "https://api.friendlypayroll.net/api"
    static let login = "\(baseURL)/login"
    static let storeRecord = "\(baseURL)/projects/store-data-time-work"
    static let storeRecordAdmin = "\(baseURL)/projects/admin-store-data-time-work"
    static let getListTotal = "\(baseURL)/projects/total-time-work-employees/"
    static let getListDetail = "\(baseURL)/projects/detail-time-work-employees/"
    static let getListProjects = "\(baseURL)/projects/data-projects"
    static let getListEmployees = "\(baseURL)/colaboradores/list-employees/"
    static let storeRegister = "\(baseURL)/store-register"

}
