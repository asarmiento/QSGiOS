//
//  Endpoints.swift
//  QGS
//
//  Created by Edin Martinez on 11/20/24.
//

enum Endpoints {
    static let baseURL = "https://api.friendlypayroll.net/api"
    static let login = "\(baseURL)/login"
    static let storeRecord = "\(baseURL)/projects/store-data-time-work"
    static let getListTotal = "\(baseURL)/projects/total-time-work-employees/"
    static let getListDetail = "\(baseURL)/projects/detail-time-work-employees/"
}
