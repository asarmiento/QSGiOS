//
//  APIServiceRecord.swift
//  QGS
//
//  Created by Edin Martinez on 12/6/24.
//
import Foundation

class APIServiceRecord {
    static let shared = APIServiceRecord()
    private let networkAdapter = NetworkManagerAdapter.shared
    private let baseURL = EndPoints.storeRecord
    
    func record(params: [String: Any], completion: @escaping (Result<RecordResponse, Error>) -> Void) {
        // Use new secure network adapter
        networkAdapter.record(params: params, completion: completion)
    }
}
