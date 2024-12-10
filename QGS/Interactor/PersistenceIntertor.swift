//
//  PersistenceIntertor.swift
//  QGS
//
//  Created by Edin Martinez on 11/29/24.
//

import Foundation


protocol PersistenceIntertor {
    
    var url: URL { get }
    
    
    func loadUsers() throws -> [UserModel]
    func saveUsers(_ users: [UserModel]) throws
    
    func LoadRecords() throws -> [RecordModel]
    func saveRecords(_ records: [RecordModel]) throws
    
    
    
    
}

protocol ListRecordDetailsProtocol{
    func getLoadRecordDetails(id: Int) async throws -> [WorkEntryDetails]
}
