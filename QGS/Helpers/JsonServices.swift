//
//  JsonServices.swift
//  QGS
//
//  Created by Edin Martinez on 11/26/24.
//

import Foundation



protocol JsonServices {
    func fetchDataRecordRepos(from endpoint:RecordEndpoints, completion: @escaping (Result<[RecordEndpoints],GHError>) -> ())
   
}
enum RecordEndpoints:String,CaseIterable{
    case dataRecordTotal
    case dataRecordDetails
    
    var description: String {
        switch self {
        case .dataRecordTotal:
            return "projects/total-time-work-employees/"
        case .dataRecordDetails:
            return "projects/detail-time-work-employees/"
        }
    }
}
enum GHError:Error{
   case invalidURL
    case invalidResponse
    case invalidData
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid Response"
        case .invalidData:
            return "Invalid Data"
        }
    }
    
    var errorDescription: [String: Any] {
        [
            NSLocalizedDescriptionKey:localizedDescription        ]
    }
}
