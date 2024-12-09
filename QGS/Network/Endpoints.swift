//
//  Endpoints.swift
//  QGS
//
//  Created by Edin Martinez on 11/20/24.
//

struct Endpoints{
    static let baseURL = "https://api.friendlypayroll.net/api/"
    static let login = Endpoints.baseURL+"login"
    static let getListTotal = Endpoints.baseURL+"projects/total-time-work-employees/"
    static let getListDetail = Endpoints.baseURL+"projects/detail-time-work-employees/"
    static let postRecord = Endpoints.baseURL+"projects/store-data-time-work"
}
