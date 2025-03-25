//
//  MessagesListener.swift
//  QGS
//
//  Created by Edin Martinez on 3/24/25.
//

import SwiftUI
import FirebaseFirestore

class MessagesListener: ObservableObject {
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    
    private var listener: ListenerRegistration?
    
    func startListeningForMessages(for employeeId: String) {
        // Obtén la instancia de Firestore
        let db = Firestore.firestore()
        
        // Ejemplo: escuchar TODOS los mensajes y su subcolección "recipients"
        // y filtrar por "recipientId" = employeeId
        // Ajusta la ruta según tu estructura real
        listener = db.collectionGroup("recipients")
            .whereField("recipientId", isEqualTo: employeeId)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error escuchando recipients: \(error.localizedDescription)")
                    return
                }
                
                guard let snapshot = querySnapshot else { return }
                
                // Recorre los cambios de documentos
                for change in snapshot.documentChanges {
                    // Solo nos interesa cuando se "agrega" un nuevo documento
                    if change.type == .added {
                        let data = change.document.data()
                        let message = data["message"] as? String ?? "Mensaje sin texto"
                        let senderId = data["senderId"] as? String ?? "Desconocido"
                        
                        // Verifica que no seas tú mismo, si tu lógica lo requiere
                        // (si no, quita este chequeo)
                        if senderId != employeeId {
                            DispatchQueue.main.async {
                                self.alertMessage = message
                                self.showAlert = true
                            }
                        }
                    }
                }
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
}
