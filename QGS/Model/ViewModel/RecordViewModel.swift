//
//  RecordViewModel.swift
//  QGS
//
//  Created by Edin Martinez on 12/9/24.
//

import SwiftUI

class RecordViewModel: ObservableObject {
    @Published var isEntradaEnabled: Bool = true
    @Published var isSalidaEnabled: Bool = true
    
    func updateButtonStates() {
        let entradaExists = RecordManager.shared.getRecordExists(for: "Entrada")
        let salidaExists = RecordManager.shared.getRecordExists(for: "Salida")
        
        DispatchQueue.main.async {
            self.isEntradaEnabled = (entradaExists == 0)
            self.isSalidaEnabled = (salidaExists == 0)
        }
    }
    
    func record(type: String, params: [String: Any], completion: @escaping (Bool) -> Void) {
        APIServiceRecord.shared.record(params: params) { result in
            DispatchQueue.main.async {
                
                switch result {
                case .success(let response):
                    if response.success {
                        RecordManager.shared.saveRecord(from: response.data)
                        completion(true)
                    } else {
                        completion(false)
                    }
                case .failure:
                    completion(false)
                }
            }
        }
    }
}
